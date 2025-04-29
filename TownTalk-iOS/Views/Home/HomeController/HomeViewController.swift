//
//  HomeViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 21/03/2023.
//

import UIKit
import SDWebImage
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase
import AVKit
import AVFoundation
import CoreLocation
import GoogleMaps
import GooglePlaces
import MessageUI

class HomeViewController: BaseViewController {
    
    @IBOutlet weak var lblFeedTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentTF: UITextField!
    @IBOutlet weak var lblCurrentLocation: UILabel!
    
    var towns = [Town]()
    let locationManager = CLLocationManager()
    var posts = [Post]()
    var feedid = 0
    let refreshControl = UIRefreshControl()
    var isAllNewsFeed: Bool = false
    var city = ""
    var userid = ""
    var postid = ""
    var count = 0
    var reportPostText = ""
    var deleteUserFeedArray : [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tableView.addSubview(refreshControl)
        Utils.fetchCurrentUser()
        self.startLoader()
        getCurrentLocationCityName(allNews: false) {
            self.stopLoader()
        }
        saveFcmToUser()
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(self.openMessage), name: Notification.Name("open_message"), object: nil)
        }
    }
    func saveFcmToUser(){
        Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(["fcm": Constants.fcmToken])
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.tableView.reloadData()
    }
    @objc func refreshTableView() {
        lblFeedTitle.text = "News Feed"
        fetchAllPosts(feed: nil,city: lblCurrentLocation.text ?? "")
        refreshControl.endRefreshing()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setView()
        
        self.tabBarController?.tabBar.isHidden = false
        NotificationCenter.default.addObserver(self, selector: #selector(fetch), name: Notification.Name("fetch_posts"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: Notification.Name("refresh"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postReported), name: Notification.Name("report_post"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(blockUser), name: Notification.Name("block_user"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fromDeepLink), name: Notification.Name("deep_link"), object: nil)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Constants.messageid != ""{
            let user = Utils.getUser(user_id: Constants.messageid)!
            Constants.messageid = ""
            let storyboard = UIStoryboard(name: "Chat", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MessageViewController.self)) as! MessageViewController
            vc.user = user
            self.navigationController?.pushViewController(vc, animated: true)

        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("open_message"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deep_link"), object: nil)
    }
    
    @objc func openMessage(notification:Notification) {
        if let userInfo = notification.userInfo as? [String: Any]{
            print(userInfo)
            let user_id = userInfo["user_id"] as? String
            let user = Utils.getUser(user_id: user_id ?? "")!
            count = count + 1
            let storyboard = UIStoryboard(name: "Chat", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MessageViewController.self)) as! MessageViewController
            vc.user = user
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    @objc func fromDeepLink(notification:Notification) {
        if let userInfo = notification.userInfo as? [String: Any]{
            print(userInfo)
            let post_id = userInfo["post_id"] as? String ?? ""
            let user_id = userInfo["user_id"] as? String ?? ""
            if Constants.isFromCustomURL{
                print("here")
                Constants.isFromCustomURL = false
                let storyboard = UIStoryboard(name: "Post", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
                vc.post_id = post_id
                vc.userid = user_id
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
    }
    
    @objc func postReported(){
        sendEmail()
        self.alert(title: "Alert", message: "This Post has been Reported")
    }
    @objc func blockUser(){
        self.alert(title: "Alert", message: "This User has been deleted and post has been reported")
    }
    
    @objc func fetch(){
        if city != "feed"{
            fetchAllPosts(city: self.city == "" ? nil : lblCurrentLocation.text ?? "")
        }
    }
    @objc func update(_ notification: NSNotification) {
        if let feed = notification.userInfo?["feed"] as? Feed {
            lblFeedTitle.text = feed.feed_name
            Constants.selectedNewsFeed = feed
            fetchAllPosts(feed: feed)
        }
    }
    func setView(){
        registerNib()
        lblName.text = "Hello, \(Auth.auth().currentUser?.displayName ?? Utils.user?.fullName ?? "")!"
        Utils.loadImage(imageView: profileImageView, urlString: Auth.auth().currentUser?.photoURL?.absoluteString ?? "" , placeHolder: UIImage(named: "placeholder"))
        lblCurrentLocation.text = Constants.currentLocation
        
        
    }
    func getCurrentLocationCityName(allNews: Bool, onCompletion: @escaping () -> Void){
        self.startLoader()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        onCompletion()
    }
    
    func fetchAllPosts(feed: Feed? = nil,city: String? = nil) {
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
                        //
                        if feed != nil{
                            let use = feed?.users?.contains(where: { user in
                                user.username == post.user?.username
                            })
                            print("post username = \(post.user?.username ?? "")")
                            print("post full name = \(post.user?.fullName ?? "")")
                            if use ?? false {
                                self.city = "feed"
                                if Utils.isBlocked(user_id: post.user_id) ?? false == true{
                                    
                                }else{
                                    if Utils.isReported(post_id: post.post_id) ?? false == true{
                                        
                                    }else{
                                        let user = Utils.getUser(user_id: post.user_id)
                                        if user?.is_deleted ?? false{
                                            
                                        }else{
                                            self.posts.append(post)
                                        }
                                    }
                                }
                            }
                        }else {
                            if city != nil{
                                self.city = "city"
                                
                                if self.lblCurrentLocation.text == post.post_location1?.city_name {
                                    //                                    self.populatePost(post: post)
                                    if Utils.isBlocked(user_id: post.user_id) ?? false == true{
                                        print("\(post.user?.username ?? "") is blocked")
                                    }else{
                                        if Utils.isReported(post_id: post.post_id) ?? false == true{
                                            
                                        }else{
                                            let user = Utils.getUser(user_id: post.user_id)
                                            if user?.is_deleted ?? false{
                                                
                                            }else{
                                                self.posts.append(post)
                                            }
                                        }
                                    }
                                }
                            }else{
                                self.city = ""
                                //                                self.populatePost(post: post)
                                if Utils.isBlocked(user_id: post.user_id) ?? false == true{
                                    
                                }else{
                                    if Utils.isReported(post_id: post.post_id) ?? false == true{
                                        
                                    }else{
                                        let user = Utils.getUser(user_id: post.user_id)
                                        if user?.is_deleted ?? false{
                                            
                                        }else{
                                            self.posts.append(post)
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
            }
            //            self.towns = self.towns.unique { town, town1 in
            //                town.name == town1.name
            //            }
            
            self.checkEmptyPosts()
            self.posts.sort(by: { $0.creation_date_time.compare($1.creation_date_time) == .orderedDescending })
            self.tableView.reloadData()
            self.stopLoader()
        })
    }
    func populatePost(post: Post){
        Utils.isPostReported(postID: post.post_id) { isReported in
            if !isReported{
                self.posts.append(post)
                self.tableView.reloadData()
                self.posts.sort(by: { $0.creation_date_time.compare($1.creation_date_time) == .orderedDescending })
                self.checkEmptyPosts()
            }
        }
    }
    func checkEmptyPosts(){
        if self.posts.isEmpty{
            self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Posts")
        }else{
            self.TableViewRemoveNoDataLable(tableview: self.tableView)
        }
    }
    private func registerNib(){
        tableView.register(UINib(nibName: String(describing: HomeFeedTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: HomeFeedTableViewCell.self))
    }
    @IBAction func editButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Location", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SelectLocationViewController.self)) as! SelectLocationViewController
        vc.delegate = self
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true)
    }
    @IBAction func searchButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Search", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SearchViewController.self)) as! SearchViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["support@towntalkapp.com"])
            mail.setMessageBody("<p>\(reportPostText)!</p>", isHTML: true)
            
            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    @IBAction func notificationButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Notification", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: NotificationViewController.self)) as! NotificationViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func newsFeedButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Popups", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: NewsFeedViewController.self)) as! NewsFeedViewController
        vc.delegate = self
        vc.locationname = lblCurrentLocation.text ?? ""
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeFeedTableViewCell.self)) as? HomeFeedTableViewCell else {return UITableViewCell()}
        cell.delegate = self
        cell.updateTraits()
        cell.heightConstraint.constant = (posts[indexPath.row].image_urls?.count ?? 0) > 0 ? 378 : 0
        cell.selectionStyle = .none
        cell.registerNibs()
        cell.posts = posts[indexPath.row]
        cell.index = indexPath.row
        if posts.count > 0{
            cell.setCell(data: posts[indexPath.item])
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Post", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
        vc.posts = posts
        vc.index = indexPath.row
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
extension HomeViewController: HomeFeedTableViewCellDelegate,CommentViewControllerDelegate{
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
                let model = CheckIn(place_id: placeID,place_photo: nil, is_hottest: false, place_name: place.name, place_address: place.formattedAddress, open_now: place.isOpen().rawValue == 1 ? true : false, close_time: "", phone: phoneNumber, email: website, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude, posts: nil, reviews: nil)
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
    func openDetail(index: Int,place_id: String) {
        self.startLoader()
        fetchPlaceDetails(index: index, placeID: place_id) { placeId in
            self.stopLoader()
            self.navigateToDetaul(place_id: placeId,index: index)
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
        //        vc.towns = towns
        //        vc.place = self.places[index]
        self.navigationController?.pushViewController(vc, animated: true)
        return
    }
    
    func openProfile(post: Post , index: Int) {
        if Auth.auth().currentUser?.uid ?? "" == post.user_id {
            self.tabBarController?.selectedIndex = 4
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        vc.fromOtherUserProfile = true
        vc.userID = posts[index].user_id
        vc.index = index
        
        
        if posts[index].user?.uid == ""{
            var customPost = posts[index].user
            customPost?.uid = posts[index].user_id
            vc.otherUser = customPost


        }else{
            vc.otherUser = posts[index].user
        }
        
        
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
                if (post.post_likes?.count ?? 0) > 0{
                    if post.post_likes?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                        post.post_likes?.remove(at: i)
                        break
                    }
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
                self.reportPostText = post.post_text
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

extension HomeViewController: NewsFeedViewControllerDelegate {
    
    
    func deletedFeed(feed: Feed) {
        self.startLoader()
        lblFeedTitle.text = "News Feed"
         deleteUserFeedArray  = feed.users ?? []
        if deleteUserFeedArray.isEmpty || deleteUserFeedArray.count == 0 {
            
        }else{
            makeApiCalls(index: 0)
        }
        // Constants.selectedNewsFeed = lblFeedTitle.text ?? ""
       // fetchAllPosts(feed: nil)
    }
    
    func makeApiCalls(index: Int) {
        guard index < self.deleteUserFeedArray.count else {
            // All API calls are done
            self.stopLoader()
            debugPrint("All API calls are complete! OLD .")
            fetchAllPosts(feed: nil)
            return
        }

        let userKey = self.deleteUserFeedArray[index].uid ?? ""
        debugPrint("qq -- OLD KEY DispatchGroup Enter \(userKey)")

        Utils.checkUsersHaveFeedCount(userKey: userKey) { feedcount in
            // Handle the response of the API call here
            if let feedCount = feedcount {
                if feedCount > 0 {
                    var count = feedCount - 1
                    Utils.updateUserFeedCount(userKey: userKey, feedCount: count) { status in
                        debugPrint("qq -- OLD KEY DispactGroup Leave -  Key \(userKey):\(status)")
                        // Now, move on to the next item in the loop
                        self.makeApiCalls(index: index + 1)
                      
                    }
                } else {
                    Utils.updateUserFeedCount(userKey: userKey, feedCount: 0) { status in
                        debugPrint("qq -- OLD KEY DispactGroup Leave -  Key \(userKey):\(status)")
                        // Now, move on to the next item in the loop
                        self.makeApiCalls(index: index + 1)
                    }
                }
            }
            else {
                Utils.updateUserFeedCount(userKey: userKey, feedCount: 0) { status in
                    debugPrint("qq -- OLD KEY DispactGroup Leave -  Key \(userKey):\(status)")
                    // Now, move on to the next item in the loop
                    self.makeApiCalls(index: index + 1)
                }
            }

        }
    }

    
    
    
    
    
    
    

    
    func allNewsFeed() {
        //        Database.database().reference().child("towns").setValue(towns.map({ town in
        //            town.dictionary
        //        }))
        isAllNewsFeed = true
        getCurrentLocationCityName(allNews: true) {
            
        }
        lblFeedTitle.text = "News Feed"
    }
    func addUsers(feed: Feed) {
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SendRequestViewController.self)) as! SendRequestViewController
        vc.delegate = self
        vc.isFromEdit = true
        vc.editFeed = feed
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func selectedNewsFeed(feed: Feed) {
        lblFeedTitle.text = feed.feed_name
        Constants.selectedNewsFeed = feed
        fetchAllPosts(feed: feed)
    }
    func searchPressed() {
        searchButtonPressed(self)
    }
    
    func notificationPressed() {
        notificationButtonPressed(self)
    }
    
    func editPressed() {
        editButtonPressed(self)
    }
    func addNewsFeed(feeds: [Feed]) {
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: CreateNewsFeedViewController.self)) as! CreateNewsFeedViewController
        vc.feeds = feeds
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

struct JSON {
    static let encoder = JSONEncoder()
}
extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
}
extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Reverse geocode the location to get the city name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Error getting city name: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first, let cityName = placemark.locality, let stateCode = placemark.administrativeArea, let country = placemark.country else {
                print("Unable to find city name")
                return
            }
            
            // Update the UI with the city name
            DispatchQueue.main.async {
                let dict = ["city": cityName, "cityLat": location.coordinate.latitude, "cityLng": location.coordinate.longitude]
                Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(dict)
                Utils.user?.city = cityName
                self.lblCurrentLocation.text = cityName
                if self.isAllNewsFeed{
                    self.fetchAllPosts(feed: nil, city: nil)
                    self.isAllNewsFeed = false
                }else{
                    self.fetchAllPosts(city: self.lblCurrentLocation.text ?? "")
                }
                
                Constants.currentLocation = cityName
                Constants.currentLatitude = location.coordinate.latitude
                Constants.currentLongitude = location.coordinate.longitude
                Constants.postLocation = PostLocation(city_name: cityName, state_name: stateCode, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,country_name: country)
                
            }
        }
        
        self.locationManager.stopUpdatingLocation()
        self.stopLoader()
    }
}
extension HomeViewController: SelectLocationViewControllerDelegate{
    func selectCity(city: String,lat: Double, lng: Double) {
        let dict = ["city": city, "cityLat": lat, "cityLng": lng] as? [String : Any] ?? [:]
        Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(dict)
        Utils.user?.city = city
        lblCurrentLocation.text = city
        Constants.currentLocation = city
        fetchAllPosts(city: city)
    }
}

extension HomeViewController: CreateNewsFeedViewControllerDelegate{
    func feedCreated() {
        print("hello")
    }
}

extension HomeViewController: SendRequestViewControllerDelegate{
    func feedUpdated() {
        
    }
    
    func feedCreated1() {
        print("hello")
    }
}
extension HomeViewController: MFMailComposeViewControllerDelegate{
    
}
extension HomeViewController: ShareWithContactsViewControllerDelegate{
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
