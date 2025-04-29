//
//  ExploreViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/03/2023.
//

import UIKit
import GoogleMaps
import GooglePlaces
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase

class ExploreViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var towns = [Town]()
    var count = 0
    var checkins = [CheckIn]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        getTowns()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getCheckins()
    }
    private func setView(){
        registerNibs()
    }
    private func registerNibs(){
        tableView.register(UINib(nibName: String(describing: PlacesTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: PlacesTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: TrendingTownsTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: TrendingTownsTableViewCell.self))
    }
    @IBAction func searchPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Search", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SearchViewController.self)) as! SearchViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func getCheckins(){
        self.startLoader()
        Database.database().reference().child("checkins").observe(.value) { snapshot in
            self.checkins.removeAll()
            if let value = snapshot.value as? [String: Any]{
                value.forEach { (key: String, value: Any) in
                    let checkin = try! FirebaseDecoder().decode(CheckIn.self, from: value as? [String:Any] ?? [:])
                    if checkin.points != nil{
                        self.checkins.append(checkin)
                    }
                }
                self.checkins.sort { $0.points ?? 0 > $1.points ?? 0 }
                self.stopLoader()
                self.tableView.reloadData()
            }else{
                self.stopLoader()
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
                let model = CheckIn(place_id: placeID,place_photo: self.checkins[index].place_photo, is_hottest: false, place_name: self.checkins[index].place_name, place_address: self.checkins[index].place_address, open_now: place.isOpen().rawValue == 1 ? true : false, close_time: "", phone: phoneNumber, email: website, latitude: self.checkins[index].latitude, longitude: self.checkins[index].longitude, posts: nil, reviews: nil)
                self.isPlaceExists(placeID: placeID) { value in
                    if !value{
                        print("added")
                        Database.database().reference().child("checkins").child(placeID).updateChildValues(model.dictionary) { error, ref in
                            if error == nil{
                                onCompletion(placeID)
                            }
                        }
                        
                    }else{
                        Database.database().reference().child("checkins").child(placeID).observe(.value) { snapshot in
                            
                        }
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
        vc.checkinData = self.checkins[index]
        self.navigationController?.pushViewController(vc, animated: true)
        return
    }
    
    func isPlaceExists(placeID: String, onCompletion: @escaping (Bool) -> Void) {
        Database.database().reference().child("checkins").child(placeID).observeSingleEvent(of: .value) { snapshot in
            onCompletion(snapshot.exists())
        }
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
            
            guard let imageURL = response?.url?.absoluteString else {
                print("Invalid data or image URL")
                completion("")
                return
            }
            
            // Save the photo URL and pass it to the completion handler
            completion(imageURL)
        }
        
        task.resume()
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
                        if name != "" && noOfCheckIns != 0{
                            self.towns.append(town)
                        }
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
}

extension ExploreViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return self.towns.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PlacesTableViewCell.self)) as? PlacesTableViewCell else { return UITableViewCell() }
            cell.setView()
            cell.towns = self.towns
            cell.selectionStyle = .none
            cell.delegate = self
            cell.checkins = self.checkins
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TrendingTownsTableViewCell.self)) as? TrendingTownsTableViewCell else { return UITableViewCell() }
            if self.towns.count > 0 {
                cell.lblLocation.text = self.towns[indexPath.row].name
                cell.lblCheckIns.text = "\(self.towns[indexPath.row].noOfCheckIns ?? 0) Check ins"
            }
            
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell()
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 380
        case 1:
            return 82
        default:
            return 0
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            return
        case 1:
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ExploreDetailViewController.self)) as! ExploreDetailViewController
            vc.town = self.towns[indexPath.row]
            vc.towns = self.towns
            vc.checkins = self.checkins
            self.navigationController?.pushViewController(vc, animated: true)
            Utils.logFirebaseEvent(eventName: "explore_nearby_hotspot")
        default:
            return
        }
        
    }
}
extension ExploreViewController: PlacesTableViewCellDelegate{
    func openDetail(index: Int) {
        self.startLoader()
        fetchPlaceDetails(index: index, placeID: self.checkins[index].place_id ?? "") { placeId in
            self.stopLoader()
            self.navigateToDetaul(place_id: placeId,index: index)
        }
    }
    func seeallpressed() {
        let storyboard = UIStoryboard(name: "Explore", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: HotspotsNearbyViewController.self)) as! HotspotsNearbyViewController
        vc.towns = self.towns
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
