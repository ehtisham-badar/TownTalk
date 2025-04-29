//
//  HotspotsNearbyViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit
import GoogleMaps
import GooglePlaces
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase

class HotspotsNearbyViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTF: UITextField!
    var places: [ShoppingPlace] = []
    var searchedPlaces: [ShoppingPlace] = []
    var selectionArray = ["Restaurant", "Bar", "Cafe", "Casino", "Department_store", "Gas_station", "Museum", "Night_club", "Shopping_mall", "Supermarket"]
    var selectedCategory = "Restaurant"
    var selectedCategoryIndex = 0
    
    var towns = [Town]()
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }
    var town: Town?
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        fetchNearbyPlaces(place: selectedCategory.lowercased())
    }
    private func setView(){
        registerNibs()
    }
    @IBAction func filterButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Explore", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: FilterPlacesViewController.self)) as! FilterPlacesViewController
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    private func registerNibs(){
        tableView.register(UINib(nibName: "PlaceTableViewCell", bundle: nil), forCellReuseIdentifier: "PlaceTableViewCell")
    }
    func filterData(for searchText: String) {
        searchedPlaces = places.filter { item in
            return item.name.lowercased().contains(searchText)
        }
    }
    
    @IBAction func searchDidChange(_ sender: Any) {
        filterData(for: searchTF.text?.lowercased() ?? "")
        if self.searchedPlaces.isEmpty{
            self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Place Found")
        }else{
            self.TableViewRemoveNoDataLable(tableview: self.tableView)
        }
        self.tableView.reloadData()
    }
    func fetchNearbyPlaces(place: String,radius: Float? = 1000) {
        self.places.removeAll()
        self.startLoader()
        let apiKey = Constants.GOOGLE_API_KEY
        let latitude = self.town == nil ? Constants.currentLatitude : self.town?.lat ?? 0.0
        let longitude = self.town == nil ? Constants.currentLongitude : self.town?.lng ?? 0.0
        let radius = Constants.filter.radius * 1609.34 == 0.0 ? 50000 : Constants.filter.radius
        let placeType = place // Place type for shopping places
        
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=\(apiKey)&location=\(latitude),\(longitude)&radius=\(radius )&type=\(placeType)"
        print(urlString)
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            self.stopLoader()
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Request failed with error: \(error)")
                DispatchQueue.main.async {
                    self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Places Found")
                    self.stopLoader()
                }
                return
            }
            
            guard let data = data else {
                print("Invalid data")
                DispatchQueue.main.async {
                    self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Places Found")
                    self.stopLoader()
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                guard let results = json?["results"] as? [[String: Any]] else {
                    print("No results found.")
                    DispatchQueue.main.async {
                        self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Places Found")
                        self.tableView.reloadData()
                        self.stopLoader()
                    }
                    return
                }
                if results.count == 0{
                    print("No results found.")
                    DispatchQueue.main.async {
                        self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Places Found")
                        self.tableView.reloadData()
                        self.stopLoader()
                    }
                    
                    return
                }
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
                        let shoppingPlace = ShoppingPlace(place_id: place_id,name: name, address: address, photo: url, openNow: openNow, lat: latitude, lng: longitude)
                        self.places.append(shoppingPlace)
                        self.places.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                        self.places = self.places.unique { place, place1 in
                            place.name == place1.name && place.address == place1.address
                        }
                        // Reload the table view with the new data
                        DispatchQueue.main.async {
                            if self.places.isEmpty{
                                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Places Found")
                            }else{
                                self.TableViewRemoveNoDataLable(tableview: self.tableView)
                            }
                            self.tableView.reloadData()
                            self.stopLoader()
                        }
                    }
                    
                    //                    }else{
                    //                        self.tableView.reloadData()
                    //                        self.stopLoader()
                    //                    }
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
            self.stopLoader()
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Request failed with error: \(error)")
                completion("")
                self.stopLoader()
                return
            }
            
            guard let imageURL = response?.url?.absoluteString else {
                print("Invalid data or image URL")
                completion("")
                self.stopLoader()
                return
            }
            
            // Save the photo URL and pass it to the completion handler
            completion(imageURL)
        }
        
        task.resume()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
extension HotspotsNearbyViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectionArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CategpryCollectionViewCell.self), for: indexPath) as? CategpryCollectionViewCell else { return UICollectionViewCell() }
        cell.lblTitle.text = selectionArray[indexPath.item]
        if selectedCategory == selectionArray[indexPath.item]{
            cell.lblTitle.textColor = UIColor.white
            cell.mainView.backgroundColor = UIColor.appColor
        }else{
            cell.lblTitle.textColor = UIColor.black
            cell.mainView.backgroundColor = UIColor.categoryColor
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = selectionArray[indexPath.item]
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.satoshiBold(withSize: 16.0)!
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        
        var textWidth = textSize.width
        if indexPath.item == 0{
            textWidth = textWidth - 20
        }
        return CGSize(width: textWidth+35, height: 50)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategory = selectionArray[indexPath.item]
        fetchNearbyPlaces(place: selectedCategory.lowercased())
        collectionView.reloadData()
    }
}

extension HotspotsNearbyViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchTextEmpty ? self.places.count : self.searchedPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceTableViewCell.self)) as? PlaceTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        if self.places.count > 0{
            cell.populateData(data: isSearchTextEmpty ? self.places[indexPath.row] : self.searchedPlaces[indexPath.row])
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        setCheckInPoint(index: indexPath.item)
        self.openDetail(index: indexPath.item)
    }
    func openDetail(index: Int) {
        self.startLoader()
        fetchPlaceDetails(index: index, placeID: self.places[index].place_id ?? "") { placeId in
            self.stopLoader()
            self.navigateToDetaul(place_id: placeId,index: index)
        }
    }
    
    func setCheckInPoint(index: Int){
        let checkedInPlace = self.places[index].address.components(separatedBy: ",")
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
            let town = Town(name: place, noOfCheckIns: 1, lat: self.places[index].lat, lng: self.places[index].lng)
            if town.name != "" && town.lat != 0.0 && town.lng != 0.0 {
                Utils.addTown(town)
                self.towns.append(town)
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
                
                print("Phone number: \(phoneNumber)")
                print("Website: \(website)")
                let model = CheckIn(place_id: placeID,place_photo: self.places[index].photo, is_hottest: false, place_name: self.places[index].name, place_address: self.places[index].address, open_now: place.isOpen().rawValue == 1 ? true : false, close_time: "", phone: phoneNumber, email: website, latitude: self.places[index].lat, longitude: self.places[index].lng, posts: nil, reviews: nil)
                self.isPlaceExists(placeID: placeID) { value in
                    if !value{
                        print("added")
                        Database.database().reference().child("checkins").child(placeID).updateChildValues(model.dictionary) { error, ref in
                            if error == nil{
                                onCompletion(placeID)
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
    func navigateToDetaul(place_id: String,index: Int){
        let storyboard = UIStoryboard(name: "Explore", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: HotspotDetailViewController.self)) as! HotspotDetailViewController
        vc.place_id = place_id
        vc.towns = towns
//        vc.place = self.places[index]
        self.navigationController?.pushViewController(vc, animated: true)
        return
    }
    
    func isPlaceExists(placeID: String, onCompletion: @escaping (Bool) -> Void) {
        Database.database().reference().child("checkins").child(placeID).observeSingleEvent(of: .value) { snapshot in
            onCompletion(snapshot.exists())
        }
    }
}
extension HotspotsNearbyViewController: FilterPlacesViewControllerDelegate{
    func applyFilters(filter: Filters) {
        fetchNearbyPlaces(place: selectedCategory.lowercased(),radius: Constants.filter.radius * 1609.34)
    }
}
