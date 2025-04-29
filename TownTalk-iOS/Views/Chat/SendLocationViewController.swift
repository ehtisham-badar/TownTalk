//
//  SendLocationViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 30/05/2023.
//

import UIKit
import GoogleMaps
import CoreLocation
import GooglePlaces


protocol SendLocationViewControllerDelegate{
    func sendLocationWithTime(location: CurrentLocation)
}

class SendLocationViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchTF: UITextField!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var hour1Box: UIImageView!
    @IBOutlet weak var hour8Box: UIImageView!
    @IBOutlet weak var hour24Box: UIImageView!
    @IBOutlet weak var switchButton: UISwitch!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var hourStack: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    
    let placesClient = GMSPlacesClient()
    var delegate: SendLocationViewControllerDelegate?
    var searchCount = 0
    var locationManager = CLLocationManager()
    var currentLocationCoords: CLLocationCoordinate2D!
    var suggestionsDataList: NSMutableArray = []
    var timer: Timer!
    var searchTextCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManagerFunction()
        setup()
        logPageView()
    }
    func setup(){
        searchTF.delegate = self
        searchTF.addTarget(self, action: #selector(textFieldDidChangedValue(sender:)), for: .editingChanged)
    }
    @objc func textFieldDidChangedValue(sender: UITextField){
        if(searchTextCount != sender.text?.count){
            searchTextCount = (sender.text?.count)!
            if(timer != nil){
                timer.invalidate()
            }
            timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(getSuggestionsFromRemoteWith), userInfo: nil, repeats: false)
            
        }
        if searchTF.text == ""{
            tableView.isHidden = true
        }else{
            tableView.isHidden = false
        }
    }
    @objc func getSuggestionsFromRemoteWith(){
        APIHandler.shared.getAddressPredictions(searchString: searchTF.text!,lat: NSNumber(value: currentLocationCoords.latitude).stringValue, lng: NSNumber(value: currentLocationCoords.longitude).stringValue, onSuccess: { (response) in
            if response is NSDictionary{
                
                let responseObject = response as! NSDictionary
                let predictions:NSArray = responseObject.object(forKey: "predictions") as! NSArray
                
                if self.suggestionsDataList != []{
                    self.suggestionsDataList.removeAllObjects()
                }
                
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
                
                self.tableView.reloadData()
            }
            
        }) { (errorMessage, errorCode, response) in
            NSLog("%@", errorMessage)
        }
    }
    
    func locationManagerFunction(){
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.delegate = self
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func hourOneButtonPressed(_ sender: Any) {
        hour1Box.image = UIImage(named: "checkBoxIcon")
        hour8Box.image = UIImage(named: "uncheckBoxIcon")
        hour24Box.image = UIImage(named: "uncheckBoxIcon")
    }
    @IBAction func hour8ButtonPressed(_ sender: Any) {
        hour8Box.image = UIImage(named: "checkBoxIcon")
        hour1Box.image = UIImage(named: "uncheckBoxIcon")
        hour24Box.image = UIImage(named: "uncheckBoxIcon")
    }
    @IBAction func hour24ButtonPressed(_ sender: Any) {
        hour24Box.image = UIImage(named: "checkBoxIcon")
        hour8Box.image = UIImage(named: "uncheckBoxIcon")
        hour1Box.image = UIImage(named: "uncheckBoxIcon")
    }
    @IBAction func onSwitchPressed(_ sender: Any) {
        hour24Box.image = UIImage(named: "uncheckBoxIcon")
        hour8Box.image = UIImage(named: "uncheckBoxIcon")
        hour1Box.image = UIImage(named: "uncheckBoxIcon")
        if switchButton.isOn{
            hourStack.isHidden = false
        }else{
            hourStack.isHidden = true
            
        }
    }
    @IBAction func currentLocationButtonPressed(_ sender: Any) {
        self.locationManager.startUpdatingLocation()
    }
    @IBAction func sendLocationButtonPressed(_ sender: Any) {
        var time: Double? = nil
        if hour1Box.image == UIImage(named: "checkBoxIcon"){
            time = hoursToMilliseconds(hours: 1)
        }else if hour8Box.image == UIImage(named: "checkBoxIcon"){
            time = hoursToMilliseconds(hours: 8)
        }else if hour24Box.image == UIImage(named: "checkBoxIcon"){
            time = hoursToMilliseconds(hours: 24)
        }else{
            time = nil
        }
        let location = CurrentLocation(latitude: currentLocationCoords.latitude, longitude: currentLocationCoords.longitude, address: lblLocation.text, duration: time, sentTime: Utils.getCurrentTimeMilliseconds())
        self.delegate?.sendLocationWithTime(location: location)
        self.navigationController?.popViewController(animated: true)
    }
    
    func hoursToMilliseconds(hours: Double) -> Double {
        let millisecondsPerHour: Double = 60 * 60 * 1000
        return hours * millisecondsPerHour
    }
}
extension SendLocationViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocationCoords = location.coordinate
        // Update map camera to current location
        let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 15)
        mapView.animate(to: camera)
        
        // Add marker to current location
        let marker = GMSMarker(position: location.coordinate)
        marker.map = mapView
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("No placemark found")
                return
            }
            
            // Use placemark to get address details
            let address = "\(placemark.thoroughfare ?? ""), \(placemark.locality ?? ""), \(placemark.administrativeArea ?? ""), \(placemark.country ?? "")"
            self.lblLocation.text = address
        }
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
extension SendLocationViewController: GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        mapView.clear() // Clear previous markers
        
        let marker = GMSMarker(position: coordinate)
        marker.map = mapView
        
        // Reverse geocode tapped location to get address
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        currentLocationCoords = location.coordinate
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("No placemark found")
                return
            }
            let address = "\(placemark.thoroughfare ?? ""), \(placemark.locality ?? ""), \(placemark.administrativeArea ?? ""), \(placemark.country ?? "")"
            self.lblLocation.text = address
        }
    }
}
extension SendLocationViewController: UITableViewDelegate , UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(suggestionsDataList != []) {
            searchCount = suggestionsDataList.count + 1
            return searchCount
        }else{
            return 0
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectLocationTableViewCell.self)) as! SelectLocationTableViewCell
        if(suggestionsDataList != [] && indexPath.item != tableView.numberOfRows(inSection: 0) - 1){
            cell.populateData(data: suggestionsDataList.object(at: indexPath.item) as! Location)
            cell.selectionStyle = .none
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = suggestionsDataList.object(at: indexPath.item) as! Location
        lblLocation.text = "\(location.main_text), \(location.secondary_text)"
        self.tableView.isHidden = true
        self.searchTF.resignFirstResponder()
        
        searchTF.text = nil
        let placeID = location.placeID
        
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: .coordinate, sessionToken: nil) {[self] (place, error) in
            if let error = error {
                print("Place fetch error: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                print("No place details found")
                return
            }
            self.currentLocationCoords = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            self.mapView.clear() // Clear previous markers
            let camera = GMSCameraPosition.camera(withTarget: currentLocationCoords, zoom: 15)
            mapView.animate(to: camera)
            
            // Add marker to current location
            let marker = GMSMarker(position: currentLocationCoords)
            marker.map = mapView
        }
    }
}
