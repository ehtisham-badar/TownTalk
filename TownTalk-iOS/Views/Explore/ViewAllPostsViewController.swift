//
//  ViewAllPostsViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 10/06/2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase
import GoogleMaps
import GooglePlaces

class ViewAllPostsViewController: BaseViewController {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var checkinData: CheckIn?
    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.posts = checkinData?.posts ?? [Post]()
        lblName.text = checkinData?.place_name ?? ""
        self.tableView.reloadData()
        registerNib()
    }
    
    private func registerNib(){
        tableView.register(UINib(nibName: String(describing: HomeFeedTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: HomeFeedTableViewCell.self))
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ViewAllPostsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

extension ViewAllPostsViewController: HomeFeedTableViewCellDelegate,CommentViewControllerDelegate{
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
extension ViewAllPostsViewController: ShareWithContactsViewControllerDelegate{
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
