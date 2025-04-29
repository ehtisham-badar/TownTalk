//
//  SearchViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 22/03/2023.
//

import UIKit
import GoogleMaps
import GooglePlaces
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase

class SearchViewController: BaseViewController,UITextFieldDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTF: UITextField!
    
    
    var titleArray = ["Users","Restaurants","Shopping", "Gas Stations", "Supermarkets","bar", "Casino", "Cafe", "Night club"]
    var imageArray = ["", "shoppingIcon","shoppingIcon", "gasstationIcon", "supermarketsIcon","shoppingIcon","shoppingIcon","shoppingIcon","shoppingIcon"]
    var selectedCategoryIndex = 0
    
    var users = [User]()
    var searchedUsers = [User]()
    var selectedTile = "Users"
    var shoppingPlaces: [ShoppingPlace] = []
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }
    var suggestionsDataList: NSMutableArray = []
    var towns = [Town]()
    var checkin = CheckIn()
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.getAllUsers { users in
            self.users = users
            //            self.tableView.reloadData()
            if self.searchedUsers.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No User")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
        }
        setView()
        getTowns()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.tableView.reloadData()
    }
    func getTowns() {
        Database.database().reference().child("towns").observe(.value) { snapshot in
            self.towns.removeAll()
            if let value = snapshot.value as? [[String:Any]] {
                value.forEach { townDict in
                    if let name = townDict["name"] as? String,
                       let noOfCheckIns = townDict["noOfCheckIns"] as? Int,
                       let lat = townDict["lat"] as? Double,
                       let lng = townDict["lng"] as? Double {
                        
                        let town = Town(name: name, noOfCheckIns: noOfCheckIns, lat: lat, lng: lng)
                        self.towns.append(town)
                    }
                }
            }
        }
    }
    
    @objc func fetchNearbyBusinesses() {
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        
        guard let apiKey = Constants.GOOGLE_API_KEY.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Invalid API key.")
            return
        }
        
        Utils.logFirebaseEvent(eventName: "search_for_businesses")
        
        let locationString = "\(Constants.currentLatitude),\(Constants.currentLongitude)"
        let radius = 1500 // Set the desired search radius in meters
        
        let parameters: [String: Any] = [
            "input": searchTF.text ?? "",
            "location": locationString,
            "radius": radius,
            "key": apiKey
        ]
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        
        guard let finalURL = urlComponents?.url else {
            print("Failed to create final URL.")
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: finalURL) { (data, response, error) in
            if let error = error {
                print("Error fetching nearby businesses: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if self.suggestionsDataList != []{
                    self.suggestionsDataList.removeAllObjects()
                }
                if let predictions = json?["predictions"] as? [[String: Any]] {
                    for case let component as NSDictionary in predictions{
                        let location = Location()
                        location.main_text = (component.object(forKey: "structured_formatting") as! NSDictionary).object(forKey: "main_text") as? String ?? DefaultValue.string
                        location.secondary_text = (component.object(forKey: "structured_formatting") as! NSDictionary).object(forKey: "secondary_text") as? String ?? DefaultValue.string
                        location.placeID = component.object(forKey: "place_id") as? String ?? DefaultValue.string
                        if(self.suggestionsDataList != []){
                            self.suggestionsDataList.add(location)
                        }else{
                            self.suggestionsDataList = NSMutableArray(object: location)
                        }
                    }
                    DispatchQueue.main.async {
                        if self.selectedCategoryIndex != 0{
                            self.tableView.reloadData()
                        }
                        
                    }
                    
                } else {
                    print("No results found.")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    func fetchShoppingPlaces(place: String) {
        self.startLoader()
        let apiKey = Constants.GOOGLE_API_KEY
        let latitude = Constants.currentLatitude
        let longitude = Constants.currentLongitude
        let radius = 50000 // Radius in meters around the current location
        let placeType = place // Place type for shopping places
        
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=\(apiKey)&location=\(latitude),\(longitude)&radius=\(radius)&type=\(placeType)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            self.stopLoader()
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Request failed with error: \(error)")
                self.stopLoader()
                return
            }
            
            guard let data = data else {
                print("Invalid data")
                self.stopLoader()
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                guard let results = json?["results"] as? [[String: Any]] else {
                    print("No results found.")
                    DispatchQueue.main.async {
                        self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Places Found")
                        if self.selectedCategoryIndex != 0{
                            self.tableView.reloadData()
                        }
                        self.stopLoader()
                    }
                    return
                }
                if results.count == 0{
                    print("No results found.")
                    DispatchQueue.main.async {
                        self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Places Found")
                        if self.selectedCategoryIndex != 0{
                            self.tableView.reloadData()
                        }
                        self.stopLoader()
                    }
                    
                    return
                }
                
                // Clear existing data
                self.shoppingPlaces.removeAll()
                
                // Fetch name, address, photo reference, open_now status, latitude, and longitude for each shopping place
                for result in results {
                    let name = result["name"] as? String ?? ""
                    let address = result["vicinity"] as? String ?? ""
                    let photos = result["photos"] as? [[String: Any]] ?? [[:]]
                    let photoReference = photos.first?["photo_reference"] as? String ?? ""
                    let place_id = result["place_id"] as? String ?? ""
                    let openingHours = result["opening_hours"] as? [String: Any] ?? [:]
                    let openNow = openingHours["open_now"] as? Bool ?? false
                    let geometry = result["geometry"] as? [String: Any] ?? [:]
                    let location = geometry["location"] as? [String: Any] ?? [:]
                    let latitude = location["lat"] as? Double ?? 0.0
                    let longitude = location["lng"] as? Double ?? 0.0
                    self.fetchPhotoURL(photoReference: photoReference) { url in
                        let shoppingPlace = ShoppingPlace(place_id: place_id, name: name, address: address, photo: url, openNow: openNow, lat: latitude, lng: longitude)
                        self.shoppingPlaces.append(shoppingPlace)
                        
                        // Reload the table view with the new data
                        DispatchQueue.main.async {
                            if self.shoppingPlaces.count > 0{
                                self.shoppingPlaces.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                            }
                            if self.selectedCategoryIndex != 0{
                                self.tableView.reloadData()
                            }
                            self.stopLoader()
                        }
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
                self.stopLoader()
            }
        }
        
        task.resume()
    }
    
    
    func fetchPhotoURL(photoReference: String, completion: @escaping (String) -> Void) {
        let apiKey = Constants.GOOGLE_API_KEY
        let urlString = "https://maps.googleapis.com/maps/api/place/photo?key=\(apiKey)&photoreference=\(photoReference)&maxwidth=400"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion("")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Request failed with error: \(error)")
                completion("")
                return
            }
            
            guard let data = data, let imageURL = response?.url?.absoluteString else {
                print("Invalid data or image URL")
                completion("")
                return
            }
            
            // Save the photo URL and pass it to the completion handler
            completion(imageURL)
        }
        
        task.resume()
    }
    
    
    private func setView(){
        registerNibs()
    }
    func filterData(for searchText: String) {
        searchedUsers = users.filter { item in
            let username = item.username ?? ""
            return username.lowercased().contains(searchText)
        }
    }
    @IBAction func searchDidChaange(_ sender: Any) {
        if selectedCategoryIndex == 0{
            
            Utils.logFirebaseEvent(eventName: "search_for_users")
            filterData(for: searchTF.text?.lowercased() ?? "")
            if self.searchedUsers.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No User")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
            self.tableView.reloadData()
        }else{
            if isSearchTextEmpty {
                self.collectionView.isHidden = false
                selectedCategoryIndex = 1
                fetchShoppingPlaces(place: self.titleArray[1])
                self.collectionView.reloadData()
                return
            }
            self.fetchNearbyBusinesses()
            self.collectionView.isHidden = true
            self.tableView.reloadData()
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchTF.resignFirstResponder()
    }
    private func registerNibs(){
        tableView.register(UINib(nibName: "SearchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchUserTableViewCell")
        tableView.register(UINib(nibName: "PlaceTableViewCell", bundle: nil), forCellReuseIdentifier: "PlaceTableViewCell")
        tableView.register(UINib(nibName: String(describing: TagBusinessTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: TagBusinessTableViewCell.self))
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CategpryCollectionViewCell.self), for: indexPath) as? CategpryCollectionViewCell else { return UICollectionViewCell() }
        if indexPath.item == 0{
            cell.iconImage.isHidden = true
            cell.widthConstraint.constant = 0
        }else{
            cell.iconImage.isHidden = false
            cell.widthConstraint.constant = 20
        }
        cell.lblTitle.text = titleArray[indexPath.item]
        cell.iconImage.image = UIImage(named: imageArray[indexPath.item])
        if selectedCategoryIndex == indexPath.item{
            cell.lblTitle.textColor = UIColor.white
            cell.iconImage.tintColor = UIColor.white
            cell.mainView.backgroundColor = UIColor.appColor
        }else{
            cell.lblTitle.textColor = UIColor.labelColor
            cell.iconImage.tintColor = UIColor.labelColor
            cell.mainView.backgroundColor = UIColor.categoryColor
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = titleArray[indexPath.item]
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.satoshiRegular(withSize: 14.0)!
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        
        var textWidth = textSize.width
        if indexPath.item == 0{
            textWidth = textWidth - 20
        }
        print(textWidth)
        return CGSize(width: textWidth+127, height: 50)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchTF.text = nil
        self.shoppingPlaces.removeAll()
        selectedCategoryIndex = indexPath.item
        if selectedCategoryIndex == 1{
            fetchShoppingPlaces(place: "restaurant")
        }else if selectedCategoryIndex == 2{
            fetchShoppingPlaces(place: "shopping_mall")
        }else if selectedCategoryIndex == 3{
            fetchShoppingPlaces(place: "gas_station")
        }else if selectedCategoryIndex == 4{
            fetchShoppingPlaces(place: "supermarket")
        }else if selectedCategoryIndex == 5{
            fetchShoppingPlaces(place: "bar")
        }else if selectedCategoryIndex == 6{
            fetchShoppingPlaces(place: "casino")
        }else if selectedCategoryIndex == 7{
            fetchShoppingPlaces(place: "cafe")
        }else if selectedCategoryIndex == 8{
            fetchShoppingPlaces(place: "night_club")
        }else{
            self.shoppingPlaces.removeAll()
            self.tableView.reloadData()
        }
        collectionView.reloadData()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedCategoryIndex == 0{
            return searchedUsers.count
        }else{
            if isSearchTextEmpty{
                return shoppingPlaces.count
            }else{
                return suggestionsDataList.count
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedCategoryIndex == 0{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchUserTableViewCell.self)) as? SearchUserTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.setTraits()
            if searchedUsers.count > 0{
                cell.setCell(user: searchedUsers[indexPath.row])
            }
            return cell
        }else{
            if isSearchTextEmpty {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceTableViewCell.self)) as? PlaceTableViewCell else { return UITableViewCell() }
                cell.selectionStyle = .none
                if shoppingPlaces.count > 0{
                    cell.lblPlaceName.text = shoppingPlaces[indexPath.row].name
                    cell.lblAddress.text = shoppingPlaces[indexPath.row].address
                    Utils.loadImage(imageView: cell.placeImage, urlString: shoppingPlaces[indexPath.row].photo, placeHolder: UIImage(named: "placeholderImage"))
                    cell.openNowView.isHidden = !shoppingPlaces[indexPath.row].openNow
                }
                return cell
            }else{
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TagBusinessTableViewCell.self)) as? TagBusinessTableViewCell else {return UITableViewCell()}
                cell.selectionStyle = .none
                if(suggestionsDataList != [] && indexPath.item != tableView.numberOfRows(inSection: 0) - 1){
                    cell.populateData(data: suggestionsDataList.object(at: indexPath.item) as! Location)
                }
                
                return cell
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch selectedCategoryIndex{
        case 0:
            return 80
        case let x where x > 0:
            return UITableView.automaticDimension
        default:
            return 0
        }
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedCategoryIndex == 0{
            if Auth.auth().currentUser?.uid ?? "" == (self.searchedUsers[indexPath.row].uid){
                self.tabBarController?.selectedIndex = 4
                return
            }
            let storyboard = UIStoryboard(name: "Home", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
            vc.fromOtherUserProfile = true
            vc.userID = searchedUsers[indexPath.row].uid ?? ""
            vc.index = indexPath.row
            vc.otherUser = searchedUsers[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }else{
            if isSearchTextEmpty {
                self.openDetail(index: indexPath.item,place_id: shoppingPlaces[indexPath.row].place_id!)
            }else{
                let sl = suggestionsDataList.object(at: indexPath.row) as! Location
                self.openDetail(index: indexPath.item,place_id: sl.placeID)
            }
        }
        
    }
    func openDetail(index: Int,place_id: String) {
        self.startLoader()
        fetchPlaceDetails(index: index, placeID: place_id) { placeId in
            self.stopLoader()
            self.navigateToDetaul(place_id: placeId,index: index)
        }
    }
    
    func setCheckInPoint(index: Int){
        let checkedInPlace = self.shoppingPlaces[index].address.components(separatedBy: ",")
        let place = checkedInPlace.last?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var flag = true
        
        for index in 0..<self.towns.count {
            print("db = \(self.towns[index].name ?? "")")
            print("\(place ?? "")")
            if self.towns[index].name == place {
                self.towns[index].noOfCheckIns = (self.towns[index].noOfCheckIns ?? 0) + 1
                Database.database().reference().child("towns").setValue(self.towns.map({ town in
                    town.dictionary
                })) { error, ref in
                    
                }
                flag = false
                break
            }
        }
        
        if(flag){
            let town = Town(name: place, noOfCheckIns: 1, lat: self.shoppingPlaces[index].lat, lng: self.shoppingPlaces[index].lng)
            if town.name != "" && town.lat != 0.0 && town.lng != 0.0 {
                if town.name != "" && town.lat != 0.0 && town.lng != 0.0 {
                    Utils.addTown(town)
                    self.towns.append(town)
                }
                
            }
        }
    }
    func fetchPlaceDetails(index: Int,placeID: String,onCompletion: @escaping (String) -> Void) {
        let placesClient = GMSPlacesClient.shared()
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: .all, sessionToken: nil) { (place, error) in
            if let error = error {
                print("Error fetching place details: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                // Access the desired place details
                let phoneNumber = place.phoneNumber ?? ""
                let website = place.website?.absoluteString ?? ""
                let city = place.addressComponents?.first(where: { $0.types.contains("locality") })?.name ?? ""
                print("City: \(city)")
                print("Phone number: \(phoneNumber)")
                print("Website: \(website)")
                let model = CheckIn(place_id: placeID,place_photo: self.shoppingPlaces[index].photo, is_hottest: false, place_name: self.shoppingPlaces[index].name, place_address: self.shoppingPlaces[index].address, open_now: place.isOpen().rawValue == 1 ? true : false, close_time: "", phone: phoneNumber, email: website, latitude: self.shoppingPlaces[index].lat, longitude: self.shoppingPlaces[index].lng, posts: nil, reviews: nil,city: city)
                if self.isSearchTextEmpty{
                    self.isPlaceExists(placeID: placeID) { value in
                        if !value{
                            print("added")
                            if self.isSearchTextEmpty {
                                Database.database().reference().child("checkins").child(placeID).updateChildValues(model.dictionary) { error, ref in
                                    if error == nil{
                                        onCompletion(placeID)
                                    }
                                }
                            }
                        }else{
                            Database.database().reference().child("checkins").child(place.placeID ?? "").updateChildValues(["open_now": place.isOpen().rawValue == 1 ? true : false])
                            onCompletion(placeID)
                            print("added already")
                        }
                    }
                }else{
                    let sl = self.suggestionsDataList.object(at: index) as! Location
                    var model1 = CheckIn(place_id: placeID,place_photo: "", is_hottest: false, place_name: sl.main_text, place_address: sl.secondary_text, open_now: place.isOpen().rawValue == 1 ? true : false, close_time: "", phone: phoneNumber, email: website, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude, posts: nil, reviews: nil)
                    self.isPlaceExists(placeID: placeID) { value in
                        if !value{
                            print("added")
                            if self.isSearchTextEmpty {
                                Database.database().reference().child("checkins").child(placeID).updateChildValues(model.dictionary) { error, ref in
                                    if error == nil{
                                        onCompletion(placeID)
                                    }
                                }
                            }else{
                                placesClient.lookUpPhotos(forPlaceID: placeID) { (photos, error) in
                                    if let error = error {
                                        print("Error fetching photos: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    let firstPhoto = photos?.results.first
                                    self.fetchPhotoURL(photoReference: firstPhoto?.value(forKey: "reference") as? String ?? "" ) { url in
                                        model1.place_photo = url
                                        Database.database().reference().child("checkins").child(placeID).updateChildValues(model1.dictionary) { error, ref in
                                            if error == nil{
                                                onCompletion(placeID)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            
                        }else{
                            Database.database().reference().child("checkins").child(place.placeID ?? "").updateChildValues(["open_now": place.isOpen().rawValue == 1 ? true : false])
                            onCompletion(placeID)
                            print("added already")
                        }
                    }
                }
                
            }
        }
    }
    func navigateToDetaul(place_id: String,index: Int){
        Database.database().reference().child("checkins").child(place_id).observeSingleEvent(of: .value) { [self] snapshot in
            if let value = snapshot.value as? [String:Any]{
                let checkin = try! FirebaseDecoder().decode(CheckIn.self, from: value)
                let storyboard = UIStoryboard(name: "Explore", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: HotspotDetailViewController.self)) as! HotspotDetailViewController
                vc.place_id = place_id
                vc.towns = towns
                vc.checkinData = checkin
                //                vc.place = self.shoppingPlaces[index]
                self.navigationController?.pushViewController(vc, animated: true)
                return
            }
        }
        
    }
    
    func isPlaceExists(placeID: String, onCompletion: @escaping (Bool) -> Void) {
        Database.database().reference().child("checkins").child(placeID).observeSingleEvent(of: .value) { snapshot in
            onCompletion(snapshot.exists())
        }
    }
}

struct ShoppingPlace: Codable{
    var place_id: String? = nil
    var name = ""
    var address = ""
    var photo = ""
    var openNow = false
    var lat = 0.0
    var lng = 0.0
}
