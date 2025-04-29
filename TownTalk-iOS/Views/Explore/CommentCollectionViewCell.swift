//
//  CommentCollectionViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit
import FirebaseAuth

class CommentCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblPostText: UILabel!
    @IBOutlet weak var likeDislikeIcon: UIImageView!
    @IBOutlet weak var lblLikeCount: UILabel!
    @IBOutlet weak var commentIcon: UIImageView!
    @IBOutlet weak var commentCount: UILabel!
    
    func updateTraits(){
        if self.isDarkModeEnabled(){
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white
            ]
            let attributedText = NSAttributedString(string: lblName.text ?? "", attributes: attributes)
            lblName.attributedText = attributedText
            commentIcon.tintColor = UIColor.white
            if likeDislikeIcon.image == UIImage(named: "dislikeIcon"){
                likeDislikeIcon.tintColor = UIColor.white
            }else{
                likeDislikeIcon.tintColor = UIColor.red
            }
        }else{
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.labelColor!
            ]
            let attributedText = NSAttributedString(string: lblName.text ?? "", attributes: attributes)
            lblName.attributedText = attributedText
            commentIcon.tintColor = UIColor.labelColor
            if likeDislikeIcon.image == UIImage(named: "dislikeIcon"){
                likeDislikeIcon.tintColor = UIColor.labelColor
            }else{
                likeDislikeIcon.tintColor = UIColor.red
            }
        }
    }
    
    
    func populateData(post: Post){
        Utils.loadImage(imageView: postImage, urlString: post.user?.profile_pic ?? "", placeHolder: UIImage(named: "launchLogo"))
        let user = Utils.getUser(user_id: post.user_id)
        lblName.text = "\(user?.fullName == "" ? user?.username ?? "" : user?.fullName ?? "")"
        lblPostText.text = post.post_text
        lblLikeCount.text = "\(post.like_count ?? 0)"
        commentCount.text = "\(post.comments?.count ?? 0)"
        let alreadyLiked = post.post_likes?.contains(where: { postLike in
            postLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        if alreadyLiked ?? false{
            likeDislikeIcon.image = UIImage(named: "likeIcon")
            likeDislikeIcon.tintColor = UIColor.red
        }else{
            likeDislikeIcon.image = UIImage(named: "dislikeIcon")
            likeDislikeIcon.tintColor = self.isDarkModeEnabled() ? UIColor.white : UIColor.black
        }
    }
}
