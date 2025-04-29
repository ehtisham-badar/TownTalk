//
//  HotspotDetailViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase
import CoreLocation
import GoogleMaps
import MobileCoreServices
import GooglePlaces
import MapKit

class HotspotDetailViewController: BaseViewController {
    
    @IBOutlet weak var lblAverageReview: UILabel!
    @IBOutlet weak var mainViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var reviewCollectionView: UICollectionView!
    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var hotspotView: UIView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblPhone: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var postViewHight: NSLayoutConstraint!
    
    @IBOutlet weak var giveReviewButton: UIButton!
    @IBOutlet weak var checkInView: UIView!
    @IBOutlet weak var postCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var postView: UIView!
    @IBOutlet weak var lblMapAddress: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    var place_id: String = ""
    var posts = [Post]()
    var checkinData: CheckIn?
    var count = 0
    var towns = [Town]()
//    var checkin: CheckIn?
    var place: ShoppingPlace?
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
    }
    
    private func setView(){
        self.startLoader()
        self.hideViews()
        
        getHotspotDetail {[self] in
            self.showViews()
            count = count + 1
            Utils.loadImage(imageView: placeImageView, urlString: self.checkinData?.place_photo ?? "", placeHolder: UIImage(named: "placeholderImage"))
            lblName.text = self.checkinData?.place_name ?? ""
            lblAddress.text = self.checkinData?.place_address ?? ""
            lblMapAddress.text = self.checkinData?.place_address ?? ""
            lblPhone.text = self.checkinData?.phone == "" ? "N/a" : self.checkinData?.phone ?? ""
            lblEmail.text = self.checkinData?.email == "" ? "N/A" : self.checkinData?.email ?? ""
            lblTime.text = (self.checkinData?.open_now ?? false) ? "Open Now" : "Closed"
            var reviewsAvergae = 0.0
            let sum = self.checkinData?.reviews?.reduce(0) { $0 + ($1.review_count ?? 0) }
            reviewsAvergae = Double(sum ?? 0) / Double(self.checkinData?.reviews?.count ?? 0)
            if reviewsAvergae == 0{
                lblAverageReview.text = "No Reviews"
            }else{
                if checkinData?.reviews?.count ?? 0 > 0 {
                    lblAverageReview.text = "\((reviewsAvergae * 10).rounded() / 10) (\(checkinData?.reviews?.count ?? 0))"
                }else{
                    lblAverageReview.text = "No Reviews"
                }
                
            }
            self.reviewCollectionView.reloadData()
            locationManagerFunction()
        }
        if (self.checkinData?.reviews?.count ?? 0) > 0{
            self.CollectionviewNoDataAvailabl(collection_view: self.reviewCollectionView, text: "No Reviews Yet!")
        }else{
            self.CollectionViewRemoveNoDataLable(collection_view: self.reviewCollectionView)
        }
        mainView.cornerRadius = 35
        mainView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        mapView.settings.setAllGesturesEnabled(false)
        mapView.isUserInteractionEnabled = false
        setTraits()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.collectionView.reloadData()
        setTraits()
    }
    func setTraits(){
        if isDarkModeEnabled() {
            do {
                // Set the map style by passing the URL of the local file.
                if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                    mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                } else {
                    print("Unable to find style.json")
                }
            } catch {
                print("One or more of the map styles failed to load. \(error)")
            }
        }
    }
    
    func hideViews(){
        placeImageView.isHidden = true
        hotspotView.isHidden = true
        mainView.isHidden = true
        checkInView.isHidden = true
    }
    func showViews(){
        placeImageView.isHidden = false
        //        hotspotView.isHidden = false
        mainView.isHidden = false
        checkInView.isHidden = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAllPosts()
    }
    func fetchAllPosts() {
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        self.startLoader()
        Database.database().reference().child(FirebaseKeys.postTable).observeSingleEvent(of: .value, with: { snapshot in
            self.posts.removeAll()
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    let posts = value as? Dictionary<String, Any>
                    posts?.forEach({ (key: String, value: Any) in
                        var post = try! FirebaseDecoder().decode(Post.self, from: value)
                        post.post_id = key
                        if self.place_id == post.tagged_business?.place_id ?? nil {
                            if Utils.isBlocked(user_id: post.user_id) ?? false == true{
                                print("\(post.user?.username ?? "") is blocked")
                            }else{
                                if Utils.isReported(post_id: post.post_id) ?? false == true{
                                    
                                }else{
                                    self.posts.append(post)
                                }
                            }
                        }
                    })
                }
            }
            self.posts.sort(by: { $0.creation_date_time.compare($1.creation_date_time) == .orderedDescending })
            if self.posts.count > 0 {
                self.showPostView()
            }else{
                self.hidePostView()
            }
            self.collectionView.reloadData()
            self.stopLoader()
        })
    }
    func hidePostView(){
        postView.isHidden = true
        postViewHight.constant = 0
        postCollectionViewHeight.constant = 0
        mainViewHeight.constant = 830
    }
    func showPostView(){
        postView.isHidden = false
        postViewHight.constant = 170
        mainViewHeight.constant = 1000
        postCollectionViewHeight.constant = 130
    }
    func locationManagerFunction(){
        let location = CLLocationCoordinate2D(latitude: self.checkinData?.latitude ?? 0.0, longitude: self.checkinData?.longitude ?? 0.0)
        let camera = GMSCameraPosition.camera(withTarget: location, zoom: 12)
        mapView.animate(to: camera)
        
        // Add marker to current location
        let marker = GMSMarker(position: location)
        marker.map = mapView
    }
    @IBAction func getDirectionsButtonPressed(_ sender: Any) {
        showActionSheet(lat: self.checkinData?.latitude ?? 0.0, lng: self.checkinData?.longitude ?? 0.0)
    }
    func showActionSheet(lat: Double, lng: Double) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let openGoogleMapsAction = UIAlertAction(title: "Open in Google Maps", style: .default) { (_) in
            self.openGoogleMapsNavigation(lat: lat, lng: lng)
        }
        actionSheet.addAction(openGoogleMapsAction)
        
        let openAppleMapsAction = UIAlertAction(title: "Open in Apple Maps", style: .default) { (_) in
            self.openAppleMapsNavigation(lat: lat, lng: lng)
        }
        actionSheet.addAction(openAppleMapsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        // For iPad support
        if let popoverPresentationController = actionSheet.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = self.view.bounds
        }
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    func openGoogleMapsNavigation(lat: Double, lng: Double) {
        if let url = URL(string: "comgooglemaps://?center=\(lat),\(lng)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // If Google Maps app is not installed, open in Safari
                if let webURL = URL(string: "https://maps.google.com/?q=\(lat),\(lng)") {
                    UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    func openAppleMapsNavigation(lat: Double, lng: Double) {
        let latitude = lat // Replace with your desired latitude
        let longitude = lng // Replace with your desired longitude
        
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func giveReviewButtonPressed(_ sender: Any) {
            let storyboard = UIStoryboard(name: "Popups", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ReviewViewController.self)) as! ReviewViewController
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.delegate = self
            self.present(vc, animated: true)
    }
    
    func isReviewExists() -> Bool{
        let reviews = self.checkinData?.reviews ?? [Reviews]()
        for review in reviews {
            if let reviewUserID = review.user_id, reviewUserID == Auth.auth().currentUser?.uid ?? "" {
                return true
            }
        }
        return false
    }
    
    
    func getHotspotDetail(onCompletion: @escaping () -> Void){
        Database.database().reference().child("checkins").child(place_id).observe(.value) { snapshot in
            if let value = snapshot.value as? [String:Any]{
                let data = try! FirebaseDecoder().decode(CheckIn.self, from: value)
                self.checkinData = data
                self.stopLoader()
                onCompletion()
            }
        }
    }
    func is24HoursBeforeCurrentTime(dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        if let date = dateFormatter.date(from: dateString) {
            let calendar = Calendar.current
            let currentDateTime = Date()
            let previousDateTime = calendar.date(byAdding: .hour, value: -24, to: currentDateTime)
            
            if let previousDateTime = previousDateTime {
                return date <= previousDateTime
            }
        }
        
        return false
    }
    
    func setCheckInPoint(){
        self.startLoader()
        let placesClient = GMSPlacesClient.shared()
        
        placesClient.lookUpPlaceID(self.checkinData?.place_id ?? "") { (place, error) in
            if let error = error {
                print("Error retrieving place details: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                let city = place.addressComponents?.first { $0.types.contains("locality") }?.shortName ?? ""
                print("City: \(city)")
                var flag = true
                
                for index in 0..<self.towns.count {
                    if self.towns[index].name == city {
                        self.towns[index].noOfCheckIns = (self.towns[index].noOfCheckIns ?? 0) + 1
                        Database.database().reference().child("towns").setValue(self.towns.map({ town in
                            town.dictionary
                        })) { error, ref in
                            self.stopLoader()
                        }
                        flag = false
                        break
                    }
                }
                
                if(flag){
                    let town = Town(name: city, noOfCheckIns: 1, lat: self.checkinData?.latitude, lng: self.checkinData?.longitude)
                    if town.name != "" && town.lat != 0.0 && town.lng != 0.0 {
                        Utils.addTown(town)
                        self.towns.append(town)
                        self.stopLoader()
                    }
                }
                return
            }
        }
    }
    @IBAction func checkinButtonPressed(_ sender: Any) {
        let userCheckedIn = self.checkinData?.checked_in_users?.filter({ user in
            user.uid == Auth.auth().currentUser?.uid ?? ""
        })
        if userCheckedIn == nil || userCheckedIn?.count == 0{
            checkin(firstTime: true)
        }else{
            if is24HoursBeforeCurrentTime(dateString: userCheckedIn?[0].checked_in_time ?? ""){
                checkin(firstTime: false)
            }else{
                print("wait for 24 hours")
                self.alert(title: "Alert", message: "Can't check in before 24 hours!")
            }
        }
        
    }
    func checkin(firstTime: Bool){
        print("check in")
        var points = self.checkinData?.points ?? 0
        points = points + 1
        self.checkinData?.points = points
        let user = User(profile_pic: Utils.user?.profile_pic ?? "", username: Utils.user?.username ?? "", email: Utils.user?.email ?? "", phone: Utils.user?.phone ?? "", zip_code: Utils.user?.zip_code ?? "",uid: Auth.auth().currentUser?.uid ?? "", checked_in_time: Utils.getCurrentDateTime())
        if firstTime{
            if self.checkinData?.checked_in_users == nil {
                self.checkinData?.checked_in_users = [user]
            }else{
                self.checkinData?.checked_in_users?.append(user)
            }
            Database.database().reference().child("checkins").child(self.place_id).updateChildValues(self.checkinData?.dictionary ?? [:])
        }else{
            var user = self.checkinData?.checked_in_users?.filter({ user in
                user.uid == Auth.auth().currentUser?.uid ?? ""
            })[0]
            user?.checked_in_time = Utils.getCurrentDateTime()
            for i in 0..<(self.checkinData?.checked_in_users?.count ?? 0){
                if user?.uid == self.checkinData?.checked_in_users?[i].uid{
                    self.checkinData?.checked_in_users?[i].checked_in_time = Utils.getCurrentDateTime()
                    Database.database().reference().child("checkins").child(self.place_id).updateChildValues(self.checkinData?.dictionary ?? [:])
                    break
                }
            }
            
        }
        
        setCheckInPoint()
        
        self.alert(title: "Success", message: "Checked In Successfully")
    }
    @IBAction func viewAllPosts(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Explore", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ViewAllPostsViewController.self)) as! ViewAllPostsViewController
        self.checkinData?.posts = self.posts
        vc.checkinData = checkinData
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func websiteButtonPressed(_ sender: Any) {
        if lblEmail.text != "N/A"{
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
            vc.name = self.checkinData?.place_name ?? ""
            vc.url = self.checkinData?.email ?? ""
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    @IBAction func phoneNumberButtonPressed(_ sender: Any) {
        guard lblPhone.text != "N/A" else { return }
        var phone = lblPhone.text ?? ""
        phone = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(phone)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension HotspotDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView{
            return posts.count
        }else{
            return self.checkinData?.reviews?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == reviewCollectionView{
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReviewCollectionViewCell.self), for: indexPath) as? ReviewCollectionViewCell else { return UICollectionViewCell() }
            cell.populateData(data: (self.checkinData?.reviews?[indexPath.item])!)
            return cell
        }else{
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CommentCollectionViewCell.self), for: indexPath) as? CommentCollectionViewCell else { return UICollectionViewCell() }
            cell.updateTraits()
            cell.populateData(post: self.posts[indexPath.item])
            return cell
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView{
            return CGSize(width: UIScreen.main.bounds.width - 50, height: 130)
        }else{
            return CGSize(width: UIScreen.main.bounds.width - 50, height: 190)
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView{
            let storyboard = UIStoryboard(name: "Post", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
            vc.posts = posts
            vc.index = indexPath.item
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
extension HotspotDetailViewController: ReviewViewControllerDelegate{
    func didGiveReview(rating: Double, review_note: String) {
        let isReviewAdded = checkinData?.reviews?.contains(where: { review in
            review.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        if isReviewAdded ?? false{
            print("review exists")
            if let index = self.checkinData?.reviews?.firstIndex(where: { review in
                review.user_id == Auth.auth().currentUser?.uid ?? ""
            }){
                self.checkinData?.reviews?[index].review_text = review_note
                self.checkinData?.reviews?[index].review_count = rating
                let ref = Database.database().reference().child("checkins").child(self.place_id)
                let updates = ["reviews": checkinData?.reviews?.map { $0.dictionary }]
                ref.updateChildValues(updates as [AnyHashable : Any]) { [self] (error, _) in
                    if error == nil {
                        self.reviewCollectionView.reloadData()
                        self.alert(title: "Alert", message: "Review added.")
                    }
                }
            }
        }else{
            print("review added")
            let review = Reviews(user_id: Auth.auth().currentUser?.uid ?? "", review_count: rating, review_text: review_note)
            
            if checkinData?.reviews == nil {
                checkinData?.reviews = [review]
            } else {
                checkinData?.reviews?.append(review)
            }
            let ref = Database.database().reference().child("checkins").child(self.place_id)
            let updates = ["reviews": checkinData?.reviews?.map { $0.dictionary }]
            ref.updateChildValues(updates as [AnyHashable : Any]) { [self] (error, _) in
                if error == nil {
                    //                self.giveReviewButton.isHidden = true
                    self.reviewCollectionView.reloadData()
                    self.alert(title: "Alert", message: "Review added.")
                }
            }
        }
    }
}
