//
//  ViewAllRepliesViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 04/04/2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ViewAllRepliesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentImageViw: UIImageView!
    @IBOutlet weak var commentarName: UILabel!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var moreIcon: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var replyTF: UITextField!
    var controller: ViewAllCommentsViewController?
    var commentt: Comment?
    var post: Post?
    var index: Int = 0
    var replies = [Replies]()
    var comments = [Comment]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        self.tableView.reloadData()
        
        self.logPageView()
    }
    func setView(){
        replyTF.becomeFirstResponder()
        Utils.loadImage(imageView: commentImageViw, urlString: commentt?.commentar_photo ?? "", placeHolder: UIImage(named: "placeholder"))
        comment.text = commentt?.comment_text ?? ""
        commentarName.text = commentt?.commentar_name ?? ""
        moreIcon.isHidden = commentt?.user_id == Auth.auth().currentUser?.uid ?? "" ? false : true
        let likeCount = post?.comments?[index].like_count ?? 0 > 0 ? "Like(\(post?.comments?[index].like_count ?? 0))" : "Like"
        likeButton.setTitle(likeCount, for: .normal)
    }
    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true) {
            NotificationCenter.default.post(Notification(name: Notification.Name("fetch_comments")))
        }
    }
    @IBAction func postReplyButton(_ sender: Any) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post?.user_id ?? "").child(post?.post_id ?? "")
        let replycount = post?.comments?[index].reply_count ?? 0
        let text = replyTF.text ?? ""
        if post?.comments?[index].replies == nil{
            post?.comments?[index].replies = [Replies(reply_text: text, replier_name: Auth.auth().currentUser?.displayName ?? "", replier_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", user_id: Auth.auth().currentUser?.uid ?? "")]
        }else{
            post?.comments?[index].replies?.append(Replies(reply_text: text, replier_name: Auth.auth().currentUser?.displayName ?? "", replier_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", user_id: Auth.auth().currentUser?.uid ?? ""))
        }
        replies.append(Replies(reply_text: text, replier_name: Auth.auth().currentUser?.displayName ?? "", replier_photo: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", user_id: Auth.auth().currentUser?.uid ?? ""))
        controller?.comments = post?.comments ?? []
        post?.comments?[index].reply_count = replycount + 1
        ref.updateChildValues(post.dictionary) { error, ref in
            if error == nil {
                self.tableView.reloadData()
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                self.replyTF.text = ""
                self.replyTF.resignFirstResponder()
            }
        }
    }
    @IBAction func moreCommentButtonPressed(_ sender: Any) {
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
                    NotificationCenter.default.post(Notification(name: Notification.Name("fetch_comments")))
                    self.tableView.reloadData()
                    self.dismiss(animated: true)
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
    @IBAction func commentLikeButtonPressed(_ sender: Any) {
        likeComment(index: index)
        let likeCount = post?.comments?[index].like_count ?? 0 > 0 ? "Like(\(post?.comments?[index].like_count ?? 0))" : "Like"
        likeButton.setTitle(likeCount, for: .normal)
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
        ref.updateChildValues(post.dictionary) { error, ref in
            if error == nil {
                self.tableView.reloadData()
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
            }
        }
    }
}

extension ViewAllRepliesViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return replies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReplyTableViewCell.self)) as? ReplyTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.delegate = self
        cell.index = indexPath.row
        Utils.loadImage(imageView: cell.replierPhoto, urlString: replies[indexPath.row].replier_photo, placeHolder: UIImage(named: "placeholder"))
        cell.reply.text = replies[indexPath.row].reply_text
        cell.replierName.text = replies[indexPath.row].replier_name
        cell.moreIcon.isHidden = replies[indexPath.row].user_id == Auth.auth().currentUser?.uid ?? "" ? false : true
        let likeCount = post?.comments?[self.index].replies?[indexPath.row].like_count ?? 0 > 0 ? "Like(\(post?.comments?[self.index].replies?[indexPath.row].like_count ?? 0))" : "Like"
        cell.likeButton.setTitle(likeCount, for: .normal)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ViewAllRepliesViewController: ReplyTableViewCellDelegate{
    func likePress(index: Int) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post?.user_id ?? "").child(post?.post_id ?? "")
        let likeCount = post?.comments?[self.index].replies?[index].like_count ?? 0
        let alreadyLiked = post?.comments?[self.index].replies?[index].reply_likes_users?.contains(where: { replyLike in
            replyLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        if alreadyLiked ?? false{
            post?.comments?[self.index].replies?[index].like_count = likeCount - 1
            for i in 0..<(post?.comments?[self.index].replies?[index].reply_likes_users?.count ?? 0){
                if post?.comments?[self.index].replies?[index].reply_likes_users?[i].user_id == Auth.auth().currentUser?.uid ?? ""{
                    post?.comments?[self.index].replies?[index].reply_likes_users?.remove(at: i)
                }
            }
        }else{
            post?.comments?[self.index].replies?[index].like_count = likeCount + 1
            if post?.comments?[self.index].replies?[index].reply_likes_users == nil{
                post?.comments?[self.index].replies?[index].reply_likes_users = [ReplyLikes(user_id: Auth.auth().currentUser?.uid ?? "")]
            }else{
                post?.comments?[self.index].replies?[index].reply_likes_users?.append(ReplyLikes(user_id: Auth.auth().currentUser?.uid ?? ""))
            }
        }
        ref.updateChildValues(post.dictionary) { error, ref in
            if error == nil {
                self.tableView.reloadData()
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_comments")))
            }
        }
    }
    
    func morePress(index: Int) {
        if replies[index].user_id != Auth.auth().currentUser?.uid ?? ""{
            return
        }
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let firstAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) {[self] action -> Void in
            guard Utils.shared.isInternetAvailable() else {
                        self.alert(title: "Error", message: "No Internet Available")
                        return
                    }
            let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post?.user_id ?? "").child(post?.post_id ?? "")
            self.post?.comments?[index].replies?.remove(at: index)
            let replyCount = self.post?.comments?[index].reply_count ?? 0
            self.replies.remove(at: index)
            self.post?.comments?[index].reply_count = replyCount - 1
            ref.updateChildValues(self.post.dictionary) { error, ref in
                if error == nil {
                    NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                    NotificationCenter.default.post(Notification(name: Notification.Name("fetch_comments")))
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
}
