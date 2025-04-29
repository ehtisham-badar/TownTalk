//
//  ExploreDetailViewController.swift
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

class ExploreDetailViewController: BaseViewController {
    
    @IBOutlet weak var lblTim: UILabel!
    @IBOutlet weak var lblCheckIns: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var town: Town?
    var places: [ShoppingPlace] = []
    var posts = [Post]()
    var post: Post!
    var count = 0
    var towns = [Town]()
    var checkins = [CheckIn]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkins = self.checkins.filter({ checkin in
            (checkin.place_address?.contains(self.town?.name ?? "") ?? false) && checkin.points != nil
        })
        setView()
        fetchAllPosts()
//        fetchNearbyPlaces(place: "bar")
//        fetchNearbyPlaces(place: "casino")
//        fetchNearbyPlaces(place: "cafe")
//        fetchNearbyPlaces(place: "night_club")
//        fetchNearbyPlaces(place: "restaurant")
    }
    private func setView(){
        registerNibs()
        lblLocation.text = self.town?.name ?? ""
        lblCheckIns.text = "\(self.town?.noOfCheckIns ?? 0)"
    }
    private func registerNibs(){
        tableView.register(UINib(nibName: String(describing: PlacesTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: PlacesTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: HomeFeedTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: HomeFeedTableViewCell.self))
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
                        if self.lblLocation.text == post.post_location1?.city_name {
                            //                                    self.populatePost(post: post)
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
            self.tableView.reloadData()
            self.stopLoader()
        })
    }
    func fetchNearbyPlaces(place: String) {
        self.startLoader()
        let apiKey = Constants.GOOGLE_API_KEY
        let latitude = self.town?.lat ?? 0.0
        let longitude = self.town?.lng ?? 0.0
        let radius = 1000
        let placeType = place
        
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
                
                // Clear existing data
                //                self.places.removeAll()
                
                // Fetch name, address, photo reference, open_now status, latitude, and longitude for each shopping place
                for result in results {
                    if let name = result["name"] as? String,
                       let address = result["vicinity"] as? String,
                       let place_id = result["place_id"] as? String,
                       let photos = result["photos"] as? [[String: Any]],
                       let photoReference = photos.first?["photo_reference"] as? String,
                       let openingHours = result["opening_hours"] as? [String: Any],
                       let openNow = openingHours["open_now"] as? Bool,
                       let geometry = result["geometry"] as? [String: Any],
                       let location = geometry["location"] as? [String: Any],
                       let latitude = location["lat"] as? Double,
                       let longitude = location["lng"] as? Double {
                        self.fetchPhotoURL(photoReference: photoReference) { url in
                            let shoppingPlace = ShoppingPlace(place_id: place_id,name: name, address: address, photo: url, openNow: openNow, lat: latitude, lng: longitude)
                            self.places.append(shoppingPlace)
                            self.places.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                            self.places = self.places.unique { place, place1 in
                                place.name == place1.name && place.address == place1.address
                            }
                            // Reload the table view with the new data
                            DispatchQueue.main.async {
                                if place == "restaurant"{
                                    self.tableView.reloadData()
                                }
                                
                                self.stopLoader()
                            }
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
    func isPlaceExists(placeID: String, onCompletion: @escaping (Bool) -> Void) {
        Database.database().reference().child("checkins").child(placeID).observeSingleEvent(of: .value) { snapshot in
            onCompletion(snapshot.exists())
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
}

extension ExploreDetailViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return self.posts.count
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeFeedTableViewCell.self)) as? HomeFeedTableViewCell else {return UITableViewCell()}
            cell.delegate = self
            cell.heightConstraint.constant = (posts[indexPath.row].image_urls?.count ?? 0) > 0 ? 378 : 0
            cell.selectionStyle = .none
            cell.registerNibs()
            cell.posts = posts[indexPath.row]
            cell.index = indexPath.row
            //        cell.moreIcon.isHidden = posts[indexPath.row].user_id == Auth.auth().currentUser?.uid ?? "" ? false : true
            if posts.count > 0{
                cell.setCell(data: posts[indexPath.item])
            }
            return cell
        default:
            return UITableViewCell()
        }
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if self.checkins.count == 0{
                return 0
            }else{
                return 400
            }
            
        case 1:
            return UITableView.automaticDimension
        default:
            return 0
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section{
        case 0:
            return
        case 1:
            let storyboard = UIStoryboard(name: "Post", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
            vc.posts = posts
            vc.index = indexPath.row
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            return
        }
    }
}

extension ExploreDetailViewController: PlacesTableViewCellDelegate{
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
        vc.town = self.town
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
extension ExploreDetailViewController: HomeFeedTableViewCellDelegate,CommentViewControllerDelegate{
    func openWebView(url: String) {
        openURLWithApp(url: URL(string: url)!)
    }
    func openURLWithApp(url: URL) {
        // Check if the URL can be opened
        if UIApplication.shared.canOpenURL(url) {
            // Open the URL
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("URL opened successfully")
                } else {
                    print("Failed to open the URL")
                    let storyboard = UIStoryboard(name: "Explore", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
                    vc.name = "Web Link"
                    vc.url = url.absoluteString
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        } else {
            print("URL cannot be opened")
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
            vc.name = "Web Link"
            vc.url = url.absoluteString
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    func openTaggedProfile(users_id: String, index: Int,user: User) {
        if Auth.auth().currentUser?.uid ?? "" == users_id{
            self.tabBarController?.selectedIndex = 4
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        vc.fromOtherUserProfile = true
        vc.userID = users_id
        vc.index = index
        vc.otherUser = user
        vc.otherUser?.uid = users_id
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openDetail(index: Int, place_id: String) {
        
    }
    
    func openProfile(post: Post , index: Int) {
        if Auth.auth().currentUser?.uid ?? "" == post.user_id{
            self.tabBarController?.selectedIndex = 4
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        vc.fromOtherUserProfile = true
        vc.userID = posts[index].user_id
        vc.index = index
        vc.otherUser = posts[index].user
        vc.otherUser?.uid = vc.userID
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openFullScreenVideoImage(url: String) {
        let storyboard = UIStoryboard(name: "Post", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: FullScreenPhotoViewController.self)) as! FullScreenPhotoViewController
        if url.contains("post_images"){
            vc.imageurl = url
        }else{
            self.playVideo(url: URL(string: url)!)
        }
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true)
    }
    
    
    func addComment(text: String, post: inout Post,index: Int) {
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post.user_id).child(post.post_id)
        let commentcount = post.comment_count ?? 0
        let uuid = UUID().uuidString
        if post.comments == nil{
            post.comments = [Comment(comment_id: uuid, comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? "")]
        }else{
            post.comments?.append(Comment(comment_id: uuid, comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? ""))
        }
        post.comment_count = commentcount + 1
        posts[index] = post
        ref.updateChildValues(post.dictionary) { error, ref in
            if error == nil {
                self.tableView.reloadData()
            }
        }
    }
    func addCommentObject(text: String, post: inout Post,index: Int){
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post.user_id).child(post.post_id)
        if post.comments == nil{
            post.comments = [Comment(comment_id: "", comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? "")]
        }else{
            post.comments?.append(Comment(comment_id: "", comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? ""))
        }
        posts[index] = post
        let uuid = UUID().uuidString
        let dic = [
            "comment_id": uuid,
            "comment_text": text,
            "commentar_name": Auth.auth().currentUser?.displayName ?? "",
            "commentar_photo": Auth.auth().currentUser?.photoURL?.absoluteString ?? "",
            "user_id": Auth.auth().currentUser?.uid ?? ""
        ]
        ref.updateChildValues(dic) { error, ref in
            if error == nil {
                self.tableView.reloadData()
            }
        }
    }
    
    func likePost(post: inout Post, index: Int) {
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post.user_id).child(post.post_id)
        
        let likecount = post.like_count ?? 0
        
        let alreadyLiked = post.post_likes?.contains(where: { postLike in
            postLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        
        if (alreadyLiked ?? false){
            post.like_count = likecount - 1
            for i in 0..<(post.post_likes?.count ?? 0){
                if post.post_likes?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                    post.post_likes?.remove(at: i)
                    break
                }
            }
        }else{
            post.like_count = likecount + 1
            if post.post_likes == nil{
                post.post_likes = [PostLikes(user_id: Auth.auth().currentUser?.uid ?? "")]
            }else{
                post.post_likes?.append(PostLikes(user_id: Auth.auth().currentUser?.uid ?? ""))
            }
        }
        posts[index] = post
        ref.updateChildValues(post.dictionary) { error, ref in
            if error == nil {
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                self.tableView.reloadData()
            }
        }
        return
    }
    
    func dislikePost(post: inout Post, index: Int) {
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post.user_id).child(post.post_id)
        
        let likecount = post.like_count ?? 0
        let dislikecount = post.dislike_count ?? 0
        
        let alreadyLiked = post.post_likes?.contains(where: { postLike in
            postLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        let alreadyDisliked = post.post_dislikes?.contains(where: { postLike in
            postLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        if !(alreadyLiked ?? false) && !(alreadyDisliked ?? false){
            post.dislike_count = dislikecount + 1
            if post.post_dislikes == nil{
                post.post_dislikes = [PostDisLikes(user_id: Auth.auth().currentUser?.uid ?? "")]
            }else{
                post.post_dislikes?.append(PostDisLikes(user_id: Auth.auth().currentUser?.uid ?? ""))
            }
            posts[index] = post
            ref.updateChildValues(post.dictionary) { error, ref in
                if error == nil {
                    self.tableView.reloadData()
                }
            }
            return
        }
        if (alreadyLiked ?? false){
            post.dislike_count = dislikecount + 1
            post.like_count = likecount - 1
            for i in 0..<(post.post_likes?.count ?? 0){
                if post.post_likes?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                    post.post_likes?.remove(at: i)
                }
            }
            if post.post_dislikes == nil{
                post.post_dislikes = [PostDisLikes(user_id: Auth.auth().currentUser?.uid ?? "")]
            }else{
                post.post_dislikes?.append(PostDisLikes(user_id: Auth.auth().currentUser?.uid ?? ""))
            }
            posts[index] = post
            ref.updateChildValues(post.dictionary) { error, ref in
                if error == nil {
                    self.tableView.reloadData()
                }
            }
            return
        }
        
        if (alreadyDisliked ?? false){
            post.dislike_count = dislikecount - 1
            for i in 0..<(post.post_dislikes?.count ?? 0){
                if post.post_dislikes?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                    post.post_dislikes?.remove(at: i)
                }
            }
            posts[index] = post
            ref.updateChildValues(post.dictionary) { error, ref in
                if error == nil {
                    self.tableView.reloadData()
                }
            }
            return
        }
    }
    
    func commentOnPost(post: inout Post, index: Int) {
        let storyboard = UIStoryboard(name: "Post", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
        vc.posts = posts
        vc.index = index
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func sharePost(post: Post) {
        self.openContactsView(post: post)
    }
    
    func openGeneralView(post: Post){
        let textToShare = "towntalk.com://\(post.post_id)/\(post.user_id)"
        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [
            .airDrop,
            .addToReadingList,
            .openInIBooks
        ]
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = self.view.bounds
        }
        present(activityViewController, animated: true, completion: nil)
    }
    
    func openContactsView(post: Post){
        let storyboard = UIStoryboard(name: "Popups", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ShareWithContactsViewController.self)) as! ShareWithContactsViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        vc.post = post
        self.present(vc, animated: true)
    }
    func viewAllComments(post: Post, index: Int) {
        let storyboard = UIStoryboard(name: "Post", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
        vc.posts = posts
        vc.index = index
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func moreClicked(index: Int, post: Post) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if posts[index].user_id == Auth.auth().currentUser?.uid ?? ""{
            alert.addAction(UIAlertAction(title: "Edit", style: .default , handler:{ (UIAlertAction)in
                let storyboard = UIStoryboard(name: "Home", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: AddPostViewController.self)) as! AddPostViewController
                vc.isFromEdit = true
                vc.post = post
                self.navigationController?.pushViewController(vc, animated: true)
            }))
        }
        if posts[index].user_id != Auth.auth().currentUser?.uid ?? ""{
            alert.addAction(UIAlertAction(title: "Report", style: .default , handler:{ (UIAlertAction)in
                let storyboard = UIStoryboard(name: "Popups", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ReportFeedViewController.self)) as! ReportFeedViewController
                vc.modalPresentationStyle = .overCurrentContext
                vc.modalTransitionStyle = .crossDissolve
                vc.post = post
                vc.user = post.user
                self.present(vc, animated: true)
            }))
        }
        
        if posts[index].user_id == Auth.auth().currentUser?.uid ?? ""{
            
            alert.addAction(UIAlertAction(title: "Delete", style: .default , handler: { (UIAlertAction) in
                guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
                let ref = Database.database().reference().child(FirebaseKeys.postTable).child(Auth.auth().currentUser?.uid ?? "").child(post.post_id)
                
                
                self.posts.remove(at: index)
                ref.removeValue { error, _ in
                    if error == nil{
                        self.tableView.reloadData()
                    }else{
                        print(error?.localizedDescription ?? "")
                    }
                }
            }))
        }
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        alert.popoverPresentationController?.sourceView = self.view
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
}
extension ExploreDetailViewController: ShareWithContactsViewControllerDelegate{
    func sharePostInMessages(chat: Chat,post: Post) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MessageViewController.self)) as! MessageViewController
        vc.chat = chat
        vc.user = chat.user
        vc.post = post
        vc.isFromShare = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
