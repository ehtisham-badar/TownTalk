//
//  CommentTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 04/04/2023.
//

import UIKit
import FirebaseAuth

protocol CommentTableViewCellDelegate{
    func morePressed(index: Int)
    func replyToComment(index: Int)
    func likeComment(index: Int)
    func dislikeComment(index: Int)
    func openTaggedProfile(users_id: String, index: Int,user: User)
    func openWebView(url: String)
}

class CommentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var comentarImageView: UIImageView!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var commentarName: UILabel!
    @IBOutlet weak var moreIcon: UIImageView!
    @IBOutlet weak var replyButton: UIButton!
    
    @IBOutlet weak var likeIcon: UIImageView!
    @IBOutlet weak var lblLikeCount: UILabel!
    @IBOutlet weak var lblDislikeCount: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    var delegate: CommentTableViewCellDelegate?
    var index: Int = 0
    var data: Comment!
    var usersInPost = [String]()
    override func awakeFromNib() {
        super.awakeFromNib()
        addGesture()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    func updateTraits(){
        if self.isDarkModeEnabled(){
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white
            ]
            let attributedText = NSAttributedString(string: commentarName.text ?? "", attributes: attributes)
            commentarName.attributedText = attributedText
            comentarImageView.borderColor = UIColor.white
            comentarImageView.borderWidth = 1.0
            if likeIcon.image == UIImage(named: "dislikeIcon"){
                likeIcon.tintColor = UIColor.white
            }else{
                likeIcon.tintColor = UIColor.red
            }
        }else{
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.labelColor!
            ]
            let attributedText = NSAttributedString(string: commentarName.text ?? "", attributes: attributes)
            commentarName.attributedText = attributedText
            comentarImageView.borderColor = UIColor.clear
            if likeIcon.image == UIImage(named: "dislikeIcon"){
                likeIcon.tintColor = UIColor.labelColor
            }else{
                likeIcon.tintColor = UIColor.red
            }
        }
    }
    @IBAction func moreCommentPressed(_ sender: Any) {
        delegate?.morePressed(index: index)
    }
    
    @IBAction func likeCommentPressed(_ sender: Any) {
        delegate?.likeComment(index: index)
    }
    
    @IBAction func replyButtonPressed(_ sender: Any) {
        delegate?.replyToComment(index: index)
    }
    @IBAction func disLikeCommentPressed(_ sender: Any) {
        delegate?.dislikeComment(index: index)
    }
    func addTag(tagName: String, data: Comment){
        let attributedString = NSMutableAttributedString(string: tagName)
        
        // Define the attributes for the matched names (e.g., red color and underline)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.appColor!
        ]
        
        // Loop through each name in the array and find the range of its occurrence in the string
        for name in data.tagged_users1 ?? [String]()  {
            let user = Utils.getUser(user_id: name)
            let range = (tagName as NSString).range(of: user?.username ?? "")
            if range.location != NSNotFound {
                // Apply the attributes to the range of the matched name
                attributedString.addAttributes(attributes, range: range)
            }
        }
        
        // Set the attributed text to the label
        comment.attributedText = attributedString
    }
    func setupCell(data: Comment){
        self.data = data
        Utils.loadImage(imageView: comentarImageView, urlString: data.commentar_photo, placeHolder: UIImage(named: "placeholder"))
        if data.tagged_users != nil{
            addTag(tagName: data.comment_text, data: data)
        }else{
            comment.text = data.comment_text
        }
        comment.text = data.comment_text
        commentarName.text = data.commentar_name
        moreIcon.isHidden = data.user_id == Auth.auth().currentUser?.uid ?? "" ? false : true
        lblLikeCount.text = "\(data.like_count ?? 0)"
        lblDislikeCount.text = "\(data.dislike_count ?? 0)"
        lblTime.text = Utils.getDaysAgo(postDate: data.creation_date_time ?? "")
        let alreadyLiked = data.comment_likes_users?.contains(where: { postLike in
            postLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        if alreadyLiked ?? false{
            likeIcon.image = UIImage(named: "likeIcon")
            likeIcon.tintColor = UIColor.red
        }else{
            likeIcon.image = UIImage(named: "dislikeIcon")
            likeIcon.tintColor = self.isDarkModeEnabled() ? UIColor.white : UIColor.black
        }
    }
    func addGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        comment.addGestureRecognizer(tap)
        comment.isUserInteractionEnabled = true
    }
    @objc func labelTapped(_ gesture: UITapGestureRecognizer) {
        if (self.data.tagged_users1?.count ?? 0) > 0{
            usersInPost = getUsersInPost(taggedUsers: self.data.tagged_users1 ?? [String](), postText: self.data.comment_text)
            guard let label = gesture.view as? UILabel,
                  let postText = data?.comment_text,
                  let taggedUsers = data?.tagged_users1 else {
                return
            }
            
            let location = gesture.location(in: label)
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(size: CGSize.zero)
            let textStorage = NSTextStorage(string: postText)
            
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            
            textContainer.lineFragmentPadding = 0.0
            textContainer.lineBreakMode = label.lineBreakMode
            textContainer.maximumNumberOfLines = label.numberOfLines
            
            let textRect = label.textRect(forBounds: label.bounds, limitedToNumberOfLines: label.numberOfLines)
            let textOffset = CGPoint(x: 0, y: (label.bounds.size.height - textRect.size.height) * 0.5)
            let locationOfTouch = CGPoint(x: location.x - textOffset.x, y: location.y - textOffset.y)
            
            let characterIndex = layoutManager.characterIndex(for: locationOfTouch, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            for taggedUser in taggedUsers {
                let user = Utils.getUser(user_id: taggedUser)
                let username = user?.username ?? ""
                if let range = postText.range(of: username) {
                    let startIndex = postText.distance(from: postText.startIndex, to: range.lowerBound)
                    let endIndex = postText.distance(from: postText.startIndex, to: range.upperBound)
                    
                    if characterIndex >= startIndex && characterIndex < endIndex {
                        // Perform action for the tapped username
                        // For example, print the UID of the tapped user
                        print("Tapped username: \(username), UID: \(taggedUser)")
                        self.delegate?.openTaggedProfile(users_id: taggedUser, index: 0,user: Utils.getUser(user_id: taggedUser)!)
                        break
                    }
                }
            }
            
        }else if self.detectLinks(in: self.comment.text ?? "").0 ?? false{
            self.delegate?.openWebView(url: self.detectLinks(in: self.comment.text ?? "").1 ?? "")
        }
    }
    func detectLinks(in text: String) -> (Bool?,String?){
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        for match in matches ?? [] {
            if match.resultType == .link {
                print("Link detected: \(match.url?.absoluteString ?? "")")
                return (true,match.url?.absoluteString ?? "")
            }
        }
        return (false,"")
    }
    func getUsersInPost(taggedUsers: [String], postText: String) -> [String] {
        var usersInPost = [String]()
        
        for taggedUser in taggedUsers {
            let user = Utils.getUser(user_id: taggedUser)
            let username = user?.username ?? ""
            
            if postText.contains(username) {
                usersInPost.append(taggedUser)
            }
        }
        
        return usersInPost
    }
}
