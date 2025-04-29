//
//  SelectLocationViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 22/03/2023.
//

import UIKit
import GoogleMaps
import Alamofire
import GooglePlaces
import CoreLocation
import GoogleMaps

protocol SelectLocationViewControllerDelegate{
    func selectCity(city: String,lat: Double, lng: Double)
}

class SelectLocationViewController: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var searchTF: UITextField!
    @IBOutlet weak var sliderDistance: UISlider!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var suggestionView: UIView!
    @IBOutlet weak var sliderView: UIStackView!
    @IBOutlet weak var suggestionViewHeight: NSLayoutConstraint!
    
    var circle = GMSCircle()
    var markers: [GMSMarker] = []
    var circles: [GMSCircle] = []
    var timer: Timer!
    var searchTextCount = 0
    var delegate: SelectLocationViewControllerDelegate?
    var currentLocationCoords: CLLocationCoordinate2D!
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation!
    var originMarker = GMSMarker()
    var suggestionsDataList: NSMutableArray = []
    var cities: [String] = []
    var searchedCities: [String] = []
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }
    var selectedlat = 0.0
    var selectedLng = 0.0
    var placeids = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        sliderDistance.value = 0
        sliderDistance.minimumValue = 0
        sliderDistance.maximumValue = 30
        lblDistance.text = "\(String(Int(sliderDistance.value))) mi"
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                print("yes")
            }
            else {
                print("no")
            }
        }
        self.mapView.delegate = self
        self.locationManager.delegate = self
        originMarker.isDraggable = true
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        let distance = Int(sliderDistance.value)
        self.searchLocality(latitude: Constants.selectedLocation.coordinate.latitude, longitude: Constants.selectedLocation.coordinate.longitude, radius: Int(Double(distance))) { cities, error in
            self.cities = cities ?? []
            DispatchQueue.main.async {
                if self.cities.isEmpty{
                    self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Cities inside the region")
                }else{
                    self.TableViewRemoveNoDataLable(tableview: self.tableView)
                }
                self.suggestionView.isHidden = false
                self.mapView.isHidden = true
                self.sliderView.isHidden = true
                self.tableView.reloadData()
            }
        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    func filterData(for searchText: String) {
        searchedCities = cities.filter { item in
            return item.lowercased().contains(searchText)
        }
    }
    @IBAction func searchValueCahanges(_ sender: Any) {
        
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
        suggestionView.isHidden = false
        mapView.isHidden = true
        sliderView.isHidden = true
    }
    
    
    @objc func getSuggestionsFromRemoteWith(){
        self.mapView.isHidden = true
        self.suggestionView.isHidden = false
        self.sliderView.isHidden = true
        self.cities.removeAll()
        APIHandler.shared.getAddressPredictionsWith(searchString: searchTF.text!,lat: NSNumber(value: currentLocationCoords.latitude).stringValue, lng: NSNumber(value: currentLocationCoords.longitude).stringValue, onSuccess: { (response) in
            if let responseObject = response as? NSDictionary,
               let predictions = responseObject.object(forKey: "predictions") as? NSArray {
                
                var cityNames: [String] = []
                
                for case let component as NSDictionary in predictions {
                    if let description = component.object(forKey: "description") as? String {
                        self.placeids.append(component.object(forKey: "place_id") as? String ?? "")
                        let cityName = description
                        cityNames.append(cityName.trimmingCharacters(in: .whitespacesAndNewlines))
                        self.cities = cityNames
                        if self.cities.isEmpty{
                            self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No City Found against search in current State")
                        }else{
                            self.TableViewRemoveNoDataLable(tableview: self.tableView)
                        }
                        self.tableView.reloadData()
                    }
                }
                
            }
        }) { (errorMessage, errorCode, response) in
            NSLog("%@", errorMessage)
        }
    }
    
    @IBAction func selectOnMapPresse(_ sender: Any) {
        suggestionView.isHidden = true
        mapView.isHidden = false
        sliderView.isHidden = false
    }
    
    @IBAction func didPressApplu(_ sender: Any) {
        let distance = Int(sliderDistance.value) == 0 ? 1000 : (Int(sliderDistance.value) * 1000)
        Constants.selectedRadius = distance
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: Constants.selectedLocation.coordinate.latitude, longitude: Constants.selectedLocation.coordinate.longitude)
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
            let city = "\(placemark.locality ?? ""), \(placemark.administrativeArea ?? ""), \(placemark.country ?? "")"
            self.selectedLng = placemark.location?.coordinate.longitude ?? 0.0
            self.selectedlat = placemark.location?.coordinate.latitude ?? 0.0
            self.cities.append(city)
            self.suggestionView.isHidden = false
            self.mapView.isHidden = true
            self.sliderView.isHidden = true
            self.TableViewRemoveNoDataLable(tableview: self.tableView)
            self.tableView.reloadData()
        }
        
        Utils.logFirebaseEvent(eventName: "set_location_parameter")
    }
    @IBAction func sliderChanged(_ sender: UISlider) {
        lblDistance.text = "\(String(Int(sliderDistance.value))) mi"
        updateCircleRadius(with: sender.value)
    }
    func updateCircleRadius(with value: Float) {
        removeCircles()
        let zoomLevel = Double(value) * 1000
        circle.fillColor = UIColor.appColor?.withAlphaComponent(0.5)
        circle.position = GMSCameraPosition(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, zoom: Float(Constants.ZOOM_LEVEL)).target
        circle.map = mapView
        circle.radius = zoomLevel
        circles.append(circle)
    }
    func searchLocality(latitude: Double, longitude: Double, radius: Int, completion: @escaping ([String]?, Error?) -> Void) {
        self.startLoader()
        let apiKey = Constants.GOOGLE_API_KEY
        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&result_type=locality&key=\(apiKey)"
        print(urlString)
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.stopLoader()
            }
            
            completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.stopLoader()
                }
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.stopLoader()
                }
                completion(nil, NSError(domain: "No data received", code: 0, userInfo: nil))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let results = json?["results"] as? [[String: Any]] {
                    let localities = results.compactMap { result -> String? in
                        return result["formatted_address"] as? String
                    }
                    DispatchQueue.main.async {
                        self.stopLoader()
                    }
                    completion(localities, nil)
                } else {
                    DispatchQueue.main.async {
                        self.stopLoader()
                    }
                    completion(nil, NSError(domain: "No results found", code: 0, userInfo: nil))
                }
            } catch {
                DispatchQueue.main.async {
                    self.stopLoader()
                }
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    func getPlaceDetails(placeID: String, onCompletion: @escaping (Bool) -> Void) {
        let placeClient = GMSPlacesClient.shared()
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt64(UInt(GMSPlaceField.name.rawValue) |
                                                                   UInt(GMSPlaceField.coordinate.rawValue)))
        
        placeClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { (place, error) in
            if let error = error {
                print("Error fetching place details: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                print("No place details found")
                onCompletion(false)
                return
            }
            
            // Get the city name from the place object
            let city = place.name ?? ""
            self.selectedLng = place.coordinate.longitude
            self.selectedlat = place.coordinate.latitude
            onCompletion(true)
        }
    }
    
    
    
}

extension SelectLocationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //        return isSearchTextEmpty ? cities.count : searchedCities.count
        
        return cities.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectLocationTableViewCell.self)) as? SelectLocationTableViewCell else {return UITableViewCell()}
        cell.lbllocation.text = cities[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchTF.resignFirstResponder()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) { [self] in
            guard cities.count > 0 else { return }
            if self.cities[indexPath.row].components(separatedBy: ",").count == 2 && self.cities[indexPath.row].contains(","){
                
                let stateCode = self.cities[indexPath.row].components(separatedBy: ",")[1].trimmingCharacters(in: .whitespacesAndNewlines)
                Constants.postLocation = PostLocation(city_name: self.cities[indexPath.row].components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", state_name: "", latitude: self.selectedlat, longitude: self.selectedLng,country_name: stateCode)
                Constants.currentLatitude = self.currentLocation.coordinate.latitude
                Constants.currentLongitude = self.currentLocation.coordinate.longitude
                if selectedlat == 0.0 {
                    self.getPlaceDetails(placeID: self.placeids[indexPath.row]) { value in
                        if value{
                            self.delegate?.selectCity(city: self.cities[indexPath.row].components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",lat: self.selectedlat, lng: self.selectedLng)
                        }
                    }
                }else{
                    self.delegate?.selectCity(city: self.cities[indexPath.row].components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",lat: self.selectedlat, lng: self.selectedLng)
                }
                
            }else if self.cities[indexPath.row].components(separatedBy: ",").count == 3 && self.cities[indexPath.row].contains(","){
                let stateCode = self.cities[indexPath.row].components(separatedBy: ",")[1].trimmingCharacters(in: .whitespacesAndNewlines)
                Constants.postLocation = PostLocation(city_name: self.cities[indexPath.row].components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", state_name: stateCode, latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
                Constants.currentLatitude = self.currentLocation.coordinate.latitude
                Constants.currentLongitude = self.currentLocation.coordinate.longitude
                if selectedlat == 0.0 {
                    self.getPlaceDetails(placeID: self.placeids[indexPath.row]) { value in
                        if value{
                            self.delegate?.selectCity(city: self.cities[indexPath.row].components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",lat: self.selectedlat, lng: self.selectedLng)
                        }
                    }
                }else{
                    self.delegate?.selectCity(city: self.cities[indexPath.row].components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",lat: self.selectedlat, lng: self.selectedLng)
                }
                
            }else{
                
                APIHandler.shared.getCurrentStateCode(lat: currentLocation.coordinate.latitude, lng: currentLocation.coordinate.longitude) { code in
                    Constants.postLocation = PostLocation(city_name: self.cities[indexPath.row], state_name: code ?? "", latitude: self.selectedlat, longitude: self.selectedLng)
                    Constants.currentLatitude = self.currentLocation.coordinate.latitude
                    Constants.currentLongitude = self.currentLocation.coordinate.longitude
                    self.getPlaceDetails(placeID: self.placeids[indexPath.row]) { value in
                        if value{
                            self.delegate?.selectCity(city: self.cities[indexPath.row],lat: self.selectedlat, lng: self.selectedLng)
                        }
                    }
                    
                }
                
            }
        }
    }
}

extension SelectLocationViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        currentLocation = locations.last
        Constants.selectedLocation = currentLocation
        currentLocationCoords = location?.coordinate
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: Float(Constants.ZOOM_LEVEL))
        circle.fillColor = UIColor.red.withAlphaComponent(0.5)
        circle.position = camera.target
        circle.radius = Double(sliderDistance.value) * 1000
        circle.map = mapView
        circles.append(circle)
        self.mapView?.animate(to: camera)
        originMarker.position = CLLocationCoordinate2D(latitude: location?.coordinate.latitude ?? 0.0, longitude: location?.coordinate.longitude ?? 0.0)
        
        
        originMarker.infoWindowAnchor = CGPoint(x: self.mapView.bounds.size.width/2+50, y: self.mapView.bounds.size.height/2)
        
        originMarker.title = "Current Location"
        originMarker.map = mapView
        markers.append(originMarker)
        self.locationManager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
extension SelectLocationViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        removeMarkers()
        let marker = GMSMarker()
        marker.position = coordinate
        marker.map = mapView
        markers.append(marker)
        let markerPosition = coordinate
        removeCircles()
        let zoomLevel = Double(sliderDistance.value) * 1000
        circle.fillColor = UIColor.appColor?.withAlphaComponent(0.5)
        circle.position = GMSCameraPosition(latitude: coordinate.latitude, longitude: coordinate.longitude, zoom: Float(Constants.ZOOM_LEVEL)).target
        circle.map = mapView
        circle.radius = zoomLevel
        circles.append(circle)
        let location = CLLocation(latitude: markerPosition.latitude, longitude: markerPosition.longitude)
        self.currentLocation = location
        Constants.selectedLocation = location
    }
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        
    }
    func removeMarkers() {
        for marker in markers {
            marker.map = nil
        }
        markers.removeAll()
    }
    func removeCircles() {
        for circle in circles {
            circle.map = nil
        }
        circles.removeAll()
    }
}

struct City{
    var name: String? = nil
    var lat: Double? = nil
    var lng: Double? = nil
    
    init(name: String? = nil, lat: Double? = nil, lng: Double? = nil) {
        self.name = name
        self.lat = lat
        self.lng = lng
    }
}
