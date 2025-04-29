//
//  MYProfileViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit
import SDWebImage
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase
import GoogleMaps
import GooglePlaces

class MYProfileViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var feedView: UIView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var settingView: UIView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var lblDisLikes: UILabel!
    @IBOutlet weak var lblNudges: UILabel!
    
    @IBOutlet weak var msgButton: UIImageView!
    @IBOutlet weak var addUserToLoginProfileFeedButton: UIImageView!
    @IBOutlet weak var bottomHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var topLocationStackViewConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var editbottomViewConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var locationIcon: UIImageView!


    
    
    @IBOutlet weak var lblLikes: UILabel!
    @IBOutlet weak var lblBio: UILabel!
    @IBOutlet weak var zodiacSignImageView: UIImageView!
    @IBOutlet weak var extraspaceUIView: UIView!

    

    
    
    
    var posts = [Post]()
    var likecount = 0
    var dislikecount = 0
    var height = 0.0
    var fromOtherUserProfile = false
    var index: Int = 0
    var userID  = Auth.auth().currentUser?.uid ?? ""
    var otherUser: User?
    var userOwnFeedsCount = 0
    var userAddHimIntoFeedCount = 0


    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        debugPrint("qq -- CurrentUser : \(Auth.auth().currentUser?.uid ?? "")")
        debugPrint("qq -- otherUser : \(otherUser?.uid ?? "")")
        setListeners()
       
    }
    
    
    
    
    
    func setListeners(){
        editProfileButton.layer.cornerRadius = 5
        zodiacSignImageView.layer.cornerRadius = zodiacSignImageView.frame.size.width / 2
        zodiacSignImageView.clipsToBounds = true
        zodiacSignImageView.isUserInteractionEnabled = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(zodiacSignImageTapped(tapGestureRecognizer:)))
        zodiacSignImageView.addGestureRecognizer(tapGestureRecognizer)
        
        let tapGestureRecognizermsgButton = UITapGestureRecognizer(target: self, action: #selector(messageButtonPressed(tapGestureRecognizer:)))
        msgButton.addGestureRecognizer(tapGestureRecognizermsgButton)
        msgButton.isUserInteractionEnabled = true
        
        
        let tapGestureRecognizeraddUserToLoginProfileFeedButton = UITapGestureRecognizer(target: self, action: #selector(addUserToLoginProfileFeedButtonPressed(tapGestureRecognizer:)))
        addUserToLoginProfileFeedButton.addGestureRecognizer(tapGestureRecognizeraddUserToLoginProfileFeedButton)
        addUserToLoginProfileFeedButton.isUserInteractionEnabled = true
        
        
        
        
        
        
    }
    
    
    
    @objc func messageButtonPressed(tapGestureRecognizer: UITapGestureRecognizer) {
        Utils.getAllUsers { user in
            user.forEach { user in
                if self.otherUser?.username == user.username {
                    self.otherUser?.uid = user.uid
                    let storyboard = UIStoryboard(name: "Chat", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MessageViewController.self)) as! MessageViewController
                    vc.user = self.otherUser
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    
    
    @objc func addUserToLoginProfileFeedButtonPressed(tapGestureRecognizer: UITapGestureRecognizer) {
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ProfileUserFeeedsViewController.self)) as! ProfileUserFeeedsViewController
        vc.delegate = self
        self.present(vc, animated: true)
        
    }
    

    
    @objc func zodiacSignImageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ZodiacSignViewController.self)) as! ZodiacSignViewController
        vc.isCurrentUser = !fromOtherUserProfile
        vc.otherUserid = otherUser?.uid ?? ""
        self.navigationController?.pushViewController(vc, animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.tableView.reloadData()
        }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        likecount = 0
        dislikecount = 0
        lblLocation.text = Constants.currentLocation

        if fromOtherUserProfile{
            
            topLocationStackViewConstraintHeight.constant = -30
            editbottomViewConstraintHeight.constant = 55
            fromOtherProfile()
            self.setFeedCountValue(userId: otherUser?.uid ?? "")
           
            
           

        }else{
            topLocationStackViewConstraintHeight.constant = 5
            editbottomViewConstraintHeight.constant = 55
            //lblLocation.text = Constants.currentLocation
            lblLocation.isHidden = true
            locationIcon.isHidden = true
            setView()
            self.setFeedCountValue(userId: Auth.auth().currentUser?.uid ?? "")
           
           
        }
        self.tableView.reloadData()
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func fromOtherProfile(){
        fetchAllPosts()
        feedView.cornerRadius = 35
        feedView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        registerNib()
        settingView.isHidden = true
        backView.isHidden = false
        editProfileButton.isEnabled = false
        editProfileButton.isHidden = true
        extraspaceUIView.isHidden = false
        msgButton.isHidden = false
        addUserToLoginProfileFeedButton.isHidden = false
//      otherUser = Utils.getUser(user_id: otherUser?.uid ?? "")
        lblName.text = otherUser?.fullName == "" ? otherUser?.username ?? "" : otherUser?.fullName ?? ""
        lblUsername.text = "@\(otherUser?.username ?? otherUser?.fullName ?? "")"
        lblLocation.text = otherUser?.city  ?? ""

        Utils.loadImage(imageView: profileImageView, urlString: otherUser?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
        lblBio.text = otherUser?.bio ?? ""
    }
    
    func setView() {
        fetchAllPosts()
        addUserToLoginProfileFeedButton.isHidden = true
        editProfileButton.isEnabled = true
        msgButton.isHidden = true
        extraspaceUIView.isHidden = true
        feedView.cornerRadius = 35
        feedView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        registerNib()
        lblName.text = Auth.auth().currentUser?.displayName
        lblUsername.text = "@\(Utils.user?.username ?? "")"
        Utils.loadImage(imageView: profileImageView, urlString: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", placeHolder: UIImage(named: "placeholder"))
        lblBio.text = Utils.user?.bio ?? ""
    }
    
    private func registerNib(){
        tableView.register(UINib(nibName: String(describing: HomeFeedTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: HomeFeedTableViewCell.self))
    }
    
    func fetchAllPosts() {
        self.startLoader()
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        Database.database().reference().child(FirebaseKeys.postTable).observeSingleEvent(of: .value, with: {[self] snapshot in
            self.posts.removeAll()
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    let posts = value as? Dictionary<String, Any>
                    posts?.forEach({ (key: String, value: Any) in
                        var post = try! FirebaseDecoder().decode(Post.self, from: value)
                        post.post_id = key
                        if post.user_id == userID{
                            self.posts.append(post)
                        }
                    })
                }
                self.posts.sort(by: { $0.creation_date_time.compare($1.creation_date_time) == .orderedDescending })
            }
            for i in 0..<posts.count{
                likecount = likecount + (posts[i].like_count ?? 0)
            }
            for i in 0..<posts.count{
                dislikecount = dislikecount + (posts[i].dislike_count ?? 0)
            }
           // lblDisLikes.text = "\(dislikecount)"
            lblNudges.text = "\(posts.count)"
            lblLikes.text = "\(likecount)"
            if self.posts.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Posts")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
            self.tableView.reloadData()
            self.stopLoader()
        })
    }
    
   
    
    
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func editProfileButtonPressed(_ sender: Any) {
        if fromOtherUserProfile {
            return
        }
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: EditProfileViewController.self)) as! EditProfileViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func settingButtonPressef(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Setting", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SettingViewController.self)) as! SettingViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension MYProfileViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeFeedTableViewCell.self)) as? HomeFeedTableViewCell else {return UITableViewCell()}
        cell.updateTraits()
        cell.heightConstraint.constant = (posts[indexPath.row].image_urls?.count ?? 0) > 0 ? 378 : 0
        cell.delegate = self
        cell.selectionStyle = .none
        cell.registerNibs()
        cell.posts = posts[indexPath.row]
        cell.index = indexPath.row
        cell.moreIcon.isHidden = posts[indexPath.row].user_id == Auth.auth().currentUser?.uid ?? "" ? false : true
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

extension MYProfileViewController: HomeFeedTableViewCellDelegate,CommentViewControllerDelegate{
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
        //        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        //        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        //        vc.fromOtherUserProfile = true
        //        self.navigationController?.pushViewController(vc, animated: true)
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
        updateLikeDislikeCount()
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
            updateLikeDislikeCount()
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
            updateLikeDislikeCount()
            return
        }
        
    }
    func updateLikeDislikeCount(){
        likecount = 0
        dislikecount = 0
        for i in 0..<posts.count{
            self.likecount = likecount + (posts[i].like_count ?? 0)
        }
        for i in 0..<posts.count{
            self.dislikecount = dislikecount + (posts[i].dislike_count ?? 0)
        }
      //  lblDisLikes.text = "\(self.dislikecount)"
        lblNudges.text = "\(posts.count)"
        lblLikes.text = "\(self.likecount)"
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
        
        alert.addAction(UIAlertAction(title: "Report", style: .default , handler:{ (UIAlertAction)in
            let storyboard = UIStoryboard(name: "Popups", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ReportFeedViewController.self)) as! ReportFeedViewController
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true)
        }))
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
                        self.fetchAllPosts()
                        
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

extension MYProfileViewController: ShareWithContactsViewControllerDelegate{
    
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



extension MYProfileViewController : ProfileUserFeeedDelegate {
    
    
    
    
    func profileUserCreateNewFeeedPassed(feedList_obbject: [Feed]) {
        self.navigateToCreateNewFeed(feedList: feedList_obbject)

    }
    
    func profileEditFeedPassed(feedList_obbject: [Feed], editableFeed: Feed) {
        self.navigateToEditNewFeed(feedObject: editableFeed)
    }
    

    
    func navigateToCreateNewFeed(feedList: [Feed]){
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: CreateNewsFeedViewController.self)) as! CreateNewsFeedViewController
        vc.feeds = feedList
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func navigateToEditNewFeed(feedObject: Feed){
        var sampleFeed = feedObject
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SendRequestViewController.self)) as! SendRequestViewController
        //vc.delegate = self
        vc.isFromEdit = true
        if let otherUserobject = self.otherUser {
            sampleFeed.users?.append(otherUserobject)
        }
        vc.editFeed = sampleFeed
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    
}



extension MYProfileViewController {
    
    func setFeedCountValue(userId:String){
        
        self.getUserOriginalFeeds(forUserID: userId) { Int in
            debugPrint("Original Feed Count : \(Int)")
            self.getFeedCountFromFireBase(userId:userId)
        }
            
    }
    
    func getFeedCountFromFireBase(userId:String){
        let ref = Database.database().reference()
        let userKey = userId
        let feedCountRef = ref.child("users").child(userKey).child("feedCount")
        
        feedCountRef.observeSingleEvent(of: .value) { (snapshot, error) in
            if let error = error {
                print("Error retrieving feed count: \(error)")
                var count  = 0 + self.userOwnFeedsCount
                self.lblDisLikes.text = "\(count)"
                self.getZodiacSignOfProfile(userId: userKey)
                return
            }
            if snapshot.exists() {
                if let feedCount = snapshot.value as? Int {
                    print("Feed Count: \(feedCount)")
                    var count  = feedCount + self.userOwnFeedsCount
                    self.lblDisLikes.text = "\(count)"
                    self.getZodiacSignOfProfile(userId: userKey)

                } else {
                    print("Feed count is in an unexpected format.")
                    var count  = 0 + self.userOwnFeedsCount
                    self.lblDisLikes.text = "\(count)"
                    self.getZodiacSignOfProfile(userId: userKey)

                }
            } else {
                print("Feed Count does not exist for this user.")
                var count  = 0 + self.userOwnFeedsCount
                self.lblDisLikes.text = "\(count)"
                self.getZodiacSignOfProfile(userId: userKey)

            }
        }
    }

    func getUserOriginalFeeds(forUserID userID: String, completion: @escaping (Int?) -> Void) {
        let databaseRef = Database.database().reference()
        let userRef = databaseRef.child("users").child(userID).child("feeds")
        userRef.observeSingleEvent(of: .value) { (snapshot) in
            if let feedArray = snapshot.value as? [[String: Any]] {
                // The "feed" node exists for the user but is empty
                debugPrint("qq -- Original Feed Count: \(feedArray.count)")
                self.userOwnFeedsCount = feedArray.count
                completion(feedArray.count)
            } else {
                // Either the "feed" node doesn't exist or it's not empty
                debugPrint("qq -- Original Feed Count: 0")
                self.userOwnFeedsCount = 0
                completion(0)
                
            }
        }
    }
  
}



extension MYProfileViewController {
    
    
    func getZodiacSignOfProfile(userId:String){
        let ref = Database.database().reference()
        let customKeyName = "ZodiacObject"
        let userObjectRef = ref.child("users").child(userId).child(customKeyName)
        // Check if the custom object key exists
        userObjectRef.observeSingleEvent(of: .value) { (snapshot, error) in
            if let error = error {
                print("Error checking if the custom object key exists: \(error)")
                self.zodiacSignImageView.image = UIImage(named: "zodiac_img")
                self.zodiacSignImageView.contentMode = .center
                
                self.getLocationOfProfile(userId: userId)
                return
            }
            if snapshot.exists() {
                if let objectData = snapshot.value as? [String: Any] {
                     // Handle the retrieved object data here
                     print("Retrieved Object Data: \(objectData)")
                    // Access the value associated with the "image" key
                    if let imageUrl = objectData["image"] as? String {
                        // Use the imageUrl here
                        print("Image URL: \(imageUrl)")
                        self.zodiacSignImageView.image = UIImage(named: imageUrl)
                        self.zodiacSignImageView.contentMode = .scaleAspectFit
                        self.getLocationOfProfile(userId: userId)

                    }
                    
                    
                 } else {
                     print("Object data is not available or is in an unexpected format.")
                     self.zodiacSignImageView.image = UIImage(named: "zodiac_img")
                     self.zodiacSignImageView.contentMode = .center
                     self.getLocationOfProfile(userId: userId)

                 }
            } else {
                // The custom object key does not exist
                print("Custom Object Key does not exist")
                self.zodiacSignImageView.image = UIImage(named: "zodiac_img")
                self.zodiacSignImageView.contentMode = .center
                self.getLocationOfProfile(userId: userId)

            }
        }
        
        
        
    }
    
    
    func getLocationOfProfile(userId:String){
        let ref = Database.database().reference()
        let userObjectRef = ref.child("users").child(userId)
        userObjectRef.observeSingleEvent(of: .value) { (snapshot, error) in
            if let error = error {
                print("Error checking if the custom object key exists: \(error)")
                return
            }
            if snapshot.exists() {
                if let objectData = snapshot.value as? [String: Any] {
                     // Handle the retrieved object data here
                     print("qq -- User Object Data: \(objectData)")
                    if let city = objectData["city"] as? String {
                        self.lblLocation.text = city
                    }
           }
                    
                    
               else {
                     print("Object data is not available or is in an unexpected format.")
                    
                 }
            } else {
                // The custom object key does not exist
                print("Custom Object Key does not exist")
            }
        }
        
        
        
    }
  
}
