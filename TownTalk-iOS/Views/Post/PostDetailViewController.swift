//
//  PostDetailViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 08/04/2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import AVFoundation
import AVKit
import CodableFirebase
import GoogleMaps
import GooglePlaces
import MBProgressHUD

class PostDetailViewController: UIViewController,UITextViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentTV: UITextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var tagTableView: UITableView!
    
    var posts = [Post]()
    var post = Post(user_id: "", post_id: "", image_urls: [""], post_text: "", tagged_business: nil, user: nil, like_count: 0, dislike_count: nil, video_urls: nil, video_urls_thumbnails: nil, feed_id: nil)
    var index: Int = 0
    var post_id: String = ""
    var userid = ""
    var taggedUsers = [String]()
    var searchedUsers = [User]()
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.getAllUsers { users in
            self.users = users
            self.tagTableView.reloadData()
        }
        
        self.logPageView()
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.tableView.reloadData()
    }
    @objc func fromDeepLink(notification:Notification) {
        if let userInfo = notification.userInfo as? [String: Any]{
            print(userInfo)
            let post_id = userInfo["post_id"] as? String ?? ""
            let user_id = userInfo["user_id"] as? String ?? ""
            if Constants.isFromCustomURL{
                print("here")
                let storyboard = UIStoryboard(name: "Post", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
                vc.post_id = post_id
                vc.userid = user_id
                //            vc.posts = posts
                //            vc.index = indexPath.row
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
    }
    
    func stopLoader(){
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    func startLoader(){
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if userid != ""{
            self.getPost()
        }else{
            registerNibs()
        }
        addObservers()
        commentTV.text = "Add a Comment"
        commentTV.textColor = UIColor.lightGray
        commentTV.delegate = self
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add a Comment"
            textView.textColor = UIColor.lightGray
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else { return }
        if text.hasSuffix("@") {
            tagView.isHidden = false
            tagTableView.reloadData()
        } else if text.contains("@") {
            let searchTerm = extractSearchTerm(from: text)
            filterNames(with: searchTerm)
        } else {
            tagView.isHidden = true
        }
    }
    func filterNames(with searchTerm: String) {
        searchedUsers = users.filter({
            let username = $0.username ?? ""
            return username.lowercased().contains(searchTerm.lowercased())
        })
        tagTableView.reloadData()
    }
    
    func insertSelectedName(_ name: String) {
        guard var text = commentTV.text else { return }
        
        if let range = text.range(of: "@\(extractSearchTerm(from: text))") {
            text.replaceSubrange(range, with: name + " ")
        }
        
        commentTV.text = text
    }
    private func extractSearchTerm(from text: String) -> String {
        guard let lastWord = text.components(separatedBy: CharacterSet.whitespaces).last else {
            return ""
        }
        
        let searchTerm = String(lastWord.dropFirst())
        return searchTerm
    }
    deinit{
        removeObservers()
    }
    
    func getPost() {
        Database.database().reference().child("posts").child(self.userid).child(self.post_id).observe(.value) { snapshot in
            if let value = snapshot.value as? [String:Any]{
                let post = try! FirebaseDecoder().decode(Post.self, from: value)
                self.post = post
                self.index = 0
                self.posts.append(self.post)
                self.registerNibs()
            }
        }
    }
    
    func registerNibs(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: String(describing: HomeFeedTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: HomeFeedTableViewCell.self))
        tableView.reloadData()
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func commentPostButton(_ sender: Any) {
        guard commentTV.text != "" else {
            self.alert(title: "Error", message: "Enter a comment")
            return
        }
        var post = posts[index]
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post.user_id ).child(post.post_id)
        let commentcount = post.comment_count ?? 0
        let uuid = UUID().uuidString
        let text = commentTV.text ?? ""
        if post.comments == nil{
            post.comments = [Comment(comment_id: uuid, comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? "",creation_date_time: Utils.getCurrentDateTime(),tagged_users1: self.taggedUsers)]
        }else{
            post.comments?.append(Comment(comment_id: uuid, comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? "",creation_date_time: Utils.getCurrentDateTime(),tagged_users1: self.taggedUsers))
        }
        posts[index].comments = post.comments
        post.comment_count = commentcount + 1
        ref.updateChildValues(post.dictionary) { error, ref in
            if error == nil {
                if self.taggedUsers.isEmpty{
                    if post.user_id != Auth.auth().currentUser?.uid ?? "" {
                        Utils.addNotification(user_id: post.user_id, post_id: post.post_id, event: .comment)
                        if let user = Utils.getUser(user_id: post.user_id){
                            Utils.sendNotification(fcm: user.fcm ?? "", event: .comment, user: user,name: Auth.auth().currentUser?.displayName ?? "",post_id: post.post_id  , user_id: post.user_id)
                        }
                    }
                    
                }else{
                    for i in 0..<self.taggedUsers.count{
                        Utils.addNotificationForTag(user_id: self.taggedUsers[i], post_id: post.post_id, event: .comment_mention,sender_user_id: Auth.auth().currentUser?.uid ?? "")
                        if let user = Utils.getUser(user_id: self.taggedUsers[i]){
                            Utils.sendNotification(fcm: user.fcm ?? "", event: .comment_mention, user: user,name: Auth.auth().currentUser?.displayName ?? "",post_id: post.post_id , user_id: post.user_id)
                        }
                    }
                }
                self.tableView.reloadData()
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                self.commentTV.text = ""
                self.commentTV.resignFirstResponder()
            }else{
                print(error?.localizedDescription ?? "")
            }
        }
    }
    func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        
        let vc = AVPlayerViewController()
        vc.player = player
        
        self.present(vc, animated: true) { vc.player?.play() }
    }
}

extension PostDetailViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == tagTableView{
            return 1
        }else{
            return 2
        }
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tagTableView{
            return searchedUsers.count
        }else{
            switch section {
            case 0:
                return 1
            case 1:
                let count = posts[index].comments?.filter({ comment in
                    Utils.getUser(user_id: comment.user_id)?.is_deleted ?? false ==  false
                }).count
                return count ?? 0
            default:
                return 0
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tagTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagUserTableViewCell") as! TagUserTableViewCell
            if searchedUsers.count > 0{
                cell.lblName.text = (searchedUsers[indexPath.row].fullName == "" ? searchedUsers[indexPath.row].username : searchedUsers[indexPath.row].fullName)
                Utils.loadImage(imageView: cell.imgView, urlString: searchedUsers[indexPath.row].profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
            }
            return cell
        }else{
            switch indexPath.section {
            case 0:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeFeedTableViewCell.self)) as? HomeFeedTableViewCell else {return UITableViewCell()}
                cell.selectionStyle = .none
                cell.updateTraits()
                cell.heightConstraint.constant = (posts[index].image_urls?.count ?? 0) > 0 ? 378 : 0
                cell.delegate = self
                cell.registerNibs()
                cell.posts = posts[index]
                cell.index = index
                if posts.count > 0{
                    cell.setCell(data: posts[index])
                }
                return cell
            case 1:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CommentTableViewCell.self)) as? CommentTableViewCell else {return UITableViewCell()}
                cell.delegate = self
                cell.updateTraits()
                cell.selectionStyle = .none
                cell.index = indexPath.row
                if (posts[index].comments?.count ?? 0) > 0{
                    let comments = posts[index].comments?.filter({ comment in
                        Utils.getUser(user_id: comment.user_id)?.is_deleted ?? false ==  false
                    })
                    cell.setupCell(data: comments?[indexPath.row] ?? Comment())
                }
                return cell
            default:
                
                return UITableViewCell()
            }
        }
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == tagTableView{
            return 50
        }else{
            switch indexPath.section {
            case 0:
                return UITableView.automaticDimension
            case 1:
                return UITableView.automaticDimension
            default:
                return 0
            }
        }
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == tagTableView{
            self.taggedUsers.append(searchedUsers[indexPath.row].uid ?? "")
            let selectedName = searchedUsers[indexPath.row].username ?? ""
            insertSelectedName(selectedName)
            tagView.isHidden = true
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        commentTV.resignFirstResponder()
    }
}
extension PostDetailViewController: HomeFeedTableViewCellDelegate{
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
    
    func openProfile(post: Post, index: Int) {
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
    
    func likePost(post: inout Post, index: Int) {
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
        if let navigationStack = self.navigationController?.viewControllers {
            for viewController in navigationStack {
                if viewController is PostDetailViewController {
                    commentTV.becomeFirstResponder()
                    return
                }
            }
        }
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
}
extension PostDetailViewController: CommentTableViewCellDelegate{
    
    func morePressed(index: Int) {
        if posts[self.index].comments?[index].user_id != Auth.auth().currentUser?.uid ?? ""{
            return
        }
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let firstAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) {[self] action -> Void in
            guard Utils.shared.isInternetAvailable() else {
                self.alert(title: "Error", message: "No Internet Available")
                return
            }
            let ref = Database.database().reference().child(FirebaseKeys.postTable).child(posts[self.index].user_id ).child(posts[self.index].post_id)
            let commentCount = self.posts[self.index].comment_count ?? 0
            if commentCount != 0{
                self.posts[self.index].comment_count = commentCount - 1
            }else{
                self.posts[self.index].comment_count = 0
            }
            self.posts[self.index].comments?.remove(at: index)
            let post = posts[self.index]
            ref.updateChildValues(post.dictionary) { error, ref in
                if error == nil {
                    NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                    self.tableView.reloadData()
                }
            }
        }
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(cancelAction)
        if let popoverController = actionSheetController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.height, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func replyToComment(index: Int) {
        
    }
    
    func likeComment(index: Int) {
        var post = posts[self.index]
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post.user_id).child(post.post_id)
        
        let likecount = post.comments?[index].like_count ?? 0
        
        let alreadyLiked = post.comments?[index].comment_likes_users?.contains(where: { commentLike in
            commentLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        
        
        if (alreadyLiked ?? false){
            post.comments?[index].like_count = likecount - 1
            for i in 0..<(post.comments?[index].comment_likes_users?.count ?? 0){
                if post.comments?[index].comment_likes_users?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                    post.comments?[index].comment_likes_users?.remove(at: i)
                }
            }
        }else{
            post.comments?[index].like_count = likecount + 1
            if post.comments?[index].comment_likes_users == nil{
                post.comments?[index].comment_likes_users = [CommentLikes(user_id: Auth.auth().currentUser?.uid ?? "")]
            }else{
                post.comments?[index].comment_likes_users?.append(CommentLikes(user_id: Auth.auth().currentUser?.uid ?? ""))
            }
        }
        posts[self.index] = post
        ref.updateChildValues(post.dictionary) { error, ref in
            if error == nil {
                if (alreadyLiked ?? false) == false{
                    if post.user_id != Auth.auth().currentUser?.uid ?? "" {
                        Utils.addNotification(user_id: post.user_id, post_id: post.post_id, event: .comment_like)
                        if let user = Utils.getUser(user_id: post.user_id){
                            Utils.sendNotification(fcm: user.fcm ?? "", event: .comment_like, user: user,name: Auth.auth().currentUser?.displayName ?? "",post_id: post.post_id , user_id: post.user_id)
                        }
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    func dislikeComment(index: Int) {
        var post = posts[self.index]
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post.user_id).child(post.post_id)
        
        let likecount = post.comments?[index].like_count ?? 0
        let dislikecount = post.comments?[index].dislike_count ?? 0
        
        let alreadyLiked = post.comments?[index].comment_likes_users?.contains(where: { commentLike in
            commentLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        let alreadyDisliked = post.comments?[index].comment_dislikes_users?.contains(where: { commentDisLike in
            commentDisLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        if !(alreadyLiked ?? false) && !(alreadyDisliked ?? false){
            post.comments?[index].dislike_count = dislikecount + 1
            if post.comments?[index].comment_dislikes_users == nil{
                post.comments?[index].comment_dislikes_users = [CommentDisLikes(user_id: Auth.auth().currentUser?.uid ?? "")]
            }else{
                post.comments?[index].comment_dislikes_users?.append(CommentDisLikes(user_id: Auth.auth().currentUser?.uid ?? ""))
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
            post.comments?[index].dislike_count  = dislikecount + 1
            post.comments?[index].like_count = likecount - 1
            for i in 0..<(post.comments?[index].comment_likes_users?.count ?? 0){
                if post.comments?[index].comment_likes_users?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                    post.comments?[index].comment_likes_users?.remove(at: i)
                }
            }
            if post.comments?[index].comment_dislikes_users == nil{
                post.comments?[index].comment_dislikes_users = [CommentDisLikes(user_id: Auth.auth().currentUser?.uid ?? "")]
            }else{
                post.comments?[index].comment_dislikes_users?.append(CommentDisLikes(user_id: Auth.auth().currentUser?.uid ?? ""))
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
            post.comments?[index].dislike_count = dislikecount - 1
            for i in 0..<(post.comments?[index].comment_dislikes_users?.count ?? 0){
                if post.comments?[index].comment_dislikes_users?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                    post.comments?[index].comment_dislikes_users?.remove(at: i)
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
}

extension PostDetailViewController: AddPostViewControllerDelegate{
    func postEdited(post: Post) {
        self.posts[index] = post
        self.tableView.reloadData()
    }
}

extension PostDetailViewController{
    func addObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(fromDeepLink), name: Notification.Name("deep_link"), object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    func removeObservers(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.bottomViewConstraint.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.bottomViewConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
}
extension PostDetailViewController: ShareWithContactsViewControllerDelegate{
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
