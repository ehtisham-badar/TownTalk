//
//  TagBusinessViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 01/04/2023.
//

import UIKit
import FirebaseDatabase
import CodableFirebase
import CoreLocation
import GooglePlaces
import GoogleMaps

protocol TagBusinessViewControllerDelegate{
    func businessSelected(business: Business)
}

class TagBusinessViewController: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchTF: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: TagBusinessViewControllerDelegate?
    var buisnesses = [Business]()
    var searchedBuisnesses = [Business]()
    var timer: Timer!
    var searchTextCount = 0
    var suggestionsDataList: NSMutableArray = []
    var searchCount = 0
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    func setup(){
        tableView.register(UINib(nibName: String(describing: TagBusinessTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: TagBusinessTableViewCell.self))
        searchTF.delegate = self
        searchTF.addTarget(self, action: #selector(textFieldDidChangedValue(sender:)), for: .editingChanged)
    }
    @objc func textFieldDidChangedValue(sender: UITextField){
        if(searchTextCount != sender.text?.count){
            searchTextCount = (sender.text?.count)!
            if(timer != nil){
                timer.invalidate()
            }
            timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(fetchNearbyBusinesses), userInfo: nil, repeats: false)
            
        }
        if searchTF.text == ""{
            tableView.isHidden = true
        }else{
            tableView.isHidden = false
        }
    }
   

    @objc func fetchNearbyBusinesses() {
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        
        guard let apiKey = Constants.GOOGLE_API_KEY.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Invalid API key.")
            return
        }
        
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
                        self.tableView.reloadData()
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


    func fetchAllBusiness(){
        self.startLoader()
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        Database.database().reference().child(FirebaseKeys.businessTable).observeSingleEvent(of: .value, with: { snapshot in
            self.buisnesses.removeAll()
            if let snapshot = snapshot.value as? [[String:Any]] {
                let business = try! FirebaseDecoder().decode([Business].self, from: snapshot)
                self.buisnesses.append(contentsOf: business)
            }
            if self.buisnesses.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Buisinesses")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
            self.tableView.reloadData()
            self.stopLoader()
        })
    }
    
    func filterData(for searchText: String) {
        searchedBuisnesses = buisnesses.filter { item in
            return item.name.lowercased().contains(searchText) || item.address.lowercased().contains(searchText)
        }
    }

    @IBAction func searchFieldDidChange(_ sender: Any) {
        
    }
}

extension TagBusinessViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(suggestionsDataList != []) {
            searchCount = suggestionsDataList.count + 1
            return searchCount
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TagBusinessTableViewCell.self)) as? TagBusinessTableViewCell else {return UITableViewCell()}
        cell.selectionStyle = .none
        if(suggestionsDataList != [] && indexPath.item != tableView.numberOfRows(inSection: 0) - 1){
            cell.populateData(data: suggestionsDataList.object(at: indexPath.item) as! Location)
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            let suggestionList = self.suggestionsDataList.object(at: indexPath.item) as! Location
            self.delegate?.businessSelected(business: Business(name: suggestionList.main_text, address: suggestionList.secondary_text, id: 0,place_id: suggestionList.placeID,lat: suggestionList.lat, lng: suggestionList.lng))
        }
    }
}
