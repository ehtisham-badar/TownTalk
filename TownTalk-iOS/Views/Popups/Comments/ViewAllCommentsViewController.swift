//
//  ViewAllCommentsViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 04/04/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ViewAllCommentsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTF: UITextField!
    
    var comments = [Comment]()
    var post: Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        
        self.logPageView()
        commentTF.becomeFirstResponder()
        NotificationCenter.default.addObserver(self, selector: #selector(fetch), name: Notification.Name("fetch_comments"), object: nil)
    }
    @objc func fetch(){
        self.tableView.reloadData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func postCommentButtonPressed(_ sender: Any) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post?.user_id ?? "").child(post?.post_id ?? "")
        let commentcount = post?.comment_count ?? 0
        let uuid = UUID().uuidString
        let text = commentTF.text ?? ""
        if post?.comments == nil{
            post?.comments = [Comment(comment_id: uuid, comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? "")]
        }else{
            post?.comments?.append(Comment(comment_id: uuid, comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? ""))
        }
        comments.append(Comment(comment_id: uuid, comment_text: text, commentar_name: Auth.auth().currentUser?.displayName ?? "", commentar_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "",user_id: Auth.auth().currentUser?.uid ?? ""))
        post?.comment_count = commentcount + 1
        ref.updateChildValues(post.dictionary) { error, ref in
            if error == nil {
                self.tableView.reloadData()
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                self.commentTF.text = ""
                self.commentTF.resignFirstResponder()
            }
        }
    }
}

extension ViewAllCommentsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CommentTableViewCell.self)) as? CommentTableViewCell else {return UITableViewCell()}
        cell.delegate = self
        let title = comments[indexPath.row].replies?.count ?? 0 > 0 ? "Reply(\(comments[indexPath.row].replies?.count ?? 0))" : "Reply"
        cell.replyButton.setTitle(title, for: .normal)
        cell.selectionStyle = .none
        cell.index = indexPath.row
        Utils.loadImage(imageView: cell.comentarImageView, urlString: comments[indexPath.row].commentar_photo, placeHolder: UIImage(named: "placeholder"))
        cell.comment.text = comments[indexPath.row].comment_text
        cell.commentarName.text = comments[indexPath.row].commentar_name
        cell.moreIcon.isHidden = comments[indexPath.row].user_id == Auth.auth().currentUser?.uid ?? "" ? false : true
        let likeCount = post?.comments?[indexPath.row].like_count ?? 0 > 0 ? "Like(\(post?.comments?[indexPath.row].like_count ?? 0))" : "Like"
        cell.likeButton.setTitle(likeCount, for: .normal)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
extension ViewAllCommentsViewController: CommentTableViewCellDelegate{
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
    func dislikeComment(index: Int) {
        
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
    
    func likeComment(index: Int) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post?.user_id ?? "").child(post?.post_id ?? "")
        let likeCount = post?.comments?[index].like_count ?? 0
        let alreadyLiked = post?.comments?[index].comment_likes_users?.contains(where: { commentLike in
            commentLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        if alreadyLiked ?? false{
            post?.comments?[index].like_count = likeCount - 1
            for i in 0..<(post?.comments?[index].comment_likes_users?.count ?? 0){
                if post?.comments?[index].comment_likes_users?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                    post?.comments?[index].comment_likes_users?.remove(at: i)
                }
            }
        }else{
            post?.comments?[index].like_count = likeCount + 1
            if post?.comments?[index].comment_likes_users == nil{
                post?.comments?[index].comment_likes_users = [CommentLikes(user_id: Auth.auth().currentUser?.uid ?? "")]
            }else{
                post?.comments?[index].comment_likes_users?.append(CommentLikes(user_id: Auth.auth().currentUser?.uid ?? ""))
            }
        }
        ref.updateChildValues(post.dictionary) { [self] (error, ref) in
            if error == nil {
                if (alreadyLiked ?? false) == false{
                    if post?.user_id != Auth.auth().currentUser?.uid ?? "" {
                        Utils.addNotification(user_id: post?.user_id ?? "", post_id: post?.post_id ?? "", event: .comment_like)
                        if let user = Utils.getUser(user_id: post?.user_id ?? ""){
                            Utils.sendNotification(fcm: user.fcm ?? "", event: .comment_like, user: user,name: Auth.auth().currentUser?.displayName ?? "",post_id: post?.post_id ?? "" , user_id: post?.user_id ?? "")
                        }
                    }
                }
                
                self.tableView.reloadData()
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
            }
        }
    }
    
    func morePressed(index: Int) {
        if comments[index].user_id != Auth.auth().currentUser?.uid ?? ""{
            return
        }
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let firstAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) {[self] action -> Void in
            guard Utils.shared.isInternetAvailable() else {
                        self.alert(title: "Error", message: "No Internet Available")
                        return
                    }
            let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post?.user_id ?? "").child(post?.post_id ?? "")
            self.post?.comments?.remove(at: index)
            let commentCount = self.post?.comment_count ?? 0
            self.comments.remove(at: index)
            self.post?.comment_count = commentCount - 1
            ref.updateChildValues(self.post.dictionary) { error, ref in
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
        let storyboard = UIStoryboard(name: "Popups", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ViewAllRepliesViewController.self)) as! ViewAllRepliesViewController
        vc.controller = self
        vc.comments = comments
        vc.commentt = comments[index]
        vc.post = post
        vc.index = index
        vc.replies = comments[index].replies ?? []
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true)
    }
}
