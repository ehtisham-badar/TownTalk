//
//  HomeFeedTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 21/03/2023.
//

import UIKit
import FirebaseAuth
import AVKit

protocol HomeFeedTableViewCellDelegate {
    func moreClicked(index: Int,  post: Post)
    func likePost(post: inout Post, index: Int)
    func dislikePost(post: inout Post,index: Int)
    func commentOnPost(post: inout Post,index: Int)
    func sharePost(post: Post)
    func viewAllComments(post: Post, index: Int)
    func openFullScreenVideoImage(url: String)
    func openProfile(post: Post, index: Int)
    func openDetail(index: Int,place_id: String)
    func openTaggedProfile(users_id: String, index: Int,user: User)
    func openWebView(url: String)
}

class HomeFeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var likeIcon: UIImageView!
    @IBOutlet weak var pageControlHeight: NSLayoutConstraint!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblPostText: UILabel!
    @IBOutlet weak var lblLikeCount: UILabel!
    @IBOutlet weak var lblDislikeCount: UILabel!
    @IBOutlet weak var lblCommentCount: UILabel!
    @IBOutlet weak var lblShareCount: UILabel!
    @IBOutlet weak var lblCommentsText: UILabel!
    @IBOutlet weak var lblFirstComment: UILabel!
    @IBOutlet weak var moreIcon: UIImageView!
    @IBOutlet weak var taglbl: UILabel!
    @IBOutlet weak var lblTag: UILabel!
    @IBOutlet weak var commentIcon: UIImageView!
    @IBOutlet weak var shareIcon: UIImageView!
    
    var usersInPost = [TaggedUsers]()
    var delegate: HomeFeedTableViewCellDelegate?
    var posts: Post?
    var index: Int = 0
    var imagesVideosToShow = [UIImage]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        pageControl.addTarget(self, action: #selector(pageControlDidChange), for: .valueChanged)
        addGesture()
    }
    
    func updateTraits(){
        if self.isDarkModeEnabled(){
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white
            ]
            let attributedText = NSAttributedString(string: lblName.text ?? "", attributes: attributes)
            lblName.attributedText = attributedText
            commentIcon.tintColor = UIColor.white
            shareIcon.tintColor = UIColor.white
            postImageView.borderColor = UIColor.white
            postImageView.borderWidth = 1.0
            if likeIcon.image == UIImage(named: "dislikeIcon"){
                likeIcon.tintColor = UIColor.white
            }else{
                likeIcon.tintColor = UIColor.red
            }
        }else{
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.labelColor!
            ]
            let attributedText = NSAttributedString(string: lblName.text ?? "", attributes: attributes)
            lblName.attributedText = attributedText
            commentIcon.tintColor = UIColor.labelColor
            shareIcon.tintColor = UIColor.labelColor
            postImageView.borderColor = UIColor.clear
            if likeIcon.image == UIImage(named: "dislikeIcon"){
                likeIcon.tintColor = UIColor.labelColor
            }else{
                likeIcon.tintColor = UIColor.red
            }
        }
    }
    func addGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        lblPostText.addGestureRecognizer(tap)
        lblName.addGestureRecognizer(tapGesture)
        lblName.isUserInteractionEnabled = true
        lblPostText.isUserInteractionEnabled = true
    }
    @objc func labelTapped(_ gesture: UITapGestureRecognizer) {
        if (posts?.tagged_users1?.count ?? 0) > 0{
            usersInPost = getUsersInPost(taggedUsers: self.posts!.tagged_users1!, postText: self.posts?.post_text ?? "")
            guard let label = gesture.view as? UILabel,
                  let postText = posts?.post_text,
                  let taggedUsers = posts?.tagged_users1 else {
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
                let user = Utils.getUser(user_id: taggedUser.user_id)!
                let username = user.username
                if let range = postText.range(of: username ?? "") {
                    let startIndex = postText.distance(from: postText.startIndex, to: range.lowerBound)
                    let endIndex = postText.distance(from: postText.startIndex, to: range.upperBound)
                    
                    if characterIndex >= startIndex && characterIndex < endIndex {
                        // Perform action for the tapped username
                        // For example, print the UID of the tapped user
                        print("Tapped username: \(username ?? ""), UID: \(taggedUser)")
                        self.delegate?.openTaggedProfile(users_id: taggedUser.user_id, index: 0,user: Utils.getUser(user_id: taggedUser.user_id)!)
                        break
                    }
                }
            }
            
        }else if self.detectLinks(in: self.lblPostText.text ?? "").0 ?? false{
            self.delegate?.openWebView(url: self.detectLinks(in: self.lblPostText.text ?? "").1 ?? "")
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
    func getUsersInPost(taggedUsers: [TaggedUsers], postText: String) -> [TaggedUsers] {
        var usersInPost = [TaggedUsers]()
        
        for taggedUser in taggedUsers {
            let user = Utils.getUser(user_id: taggedUser.user_id)!
            let username = user.username ?? ""
            
            if postText.contains(username) {
                usersInPost.append(taggedUser)
            }
        }
        
        return usersInPost
    }
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        self.delegate?.openDetail(index: self.index, place_id: self.posts?.tagged_business?.place_id ?? "")
    }
    
    
    @objc func pageControlDidChange() {
        let selectedPage = pageControl.currentPage
        let indexPath = IndexPath(item: selectedPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func registerNibs(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: String(describing: FeedPhotosCollectionViewCell.self), bundle: nil),forCellWithReuseIdentifier: String(describing: FeedPhotosCollectionViewCell.self))
        collectionView.reloadData()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    func addTag(tagName: String, data: Post){
        let attributedString = NSMutableAttributedString(string: tagName)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.appColor!
        ]
        for name in data.tagged_users1 ?? [TaggedUsers]()  {
            let user = Utils.getUser(user_id: name.user_id)
            let range = (tagName as NSString).range(of: user?.username ?? "")
            if range.location != NSNotFound {
                attributedString.addAttributes(attributes, range: range)
            }
        }
        lblPostText.attributedText = attributedString
    }
    func setCell(data: Post){
        let user = Utils.getUser(user_id: data.user_id)
        Utils.loadImage(imageView: postImageView, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
        let name = user?.fullName == "" || user?.fullName == nil || user?.fullName == " " ? user?.username ?? "" : user?.fullName ?? ""
        if data.tagged_users1 != nil{
            addTag(tagName: data.post_text, data: data)
        }else{
            lblPostText.text = data.post_text
        }
        if data.tagged_business != nil{
            self.addAttributedName(label: lblName, name: name,tag: data.tagged_business?.name ?? "")
        }else{
            self.addAttributedName(label: lblName, name: name)
        }
        
        lblShareCount.text = "\(data.share_count ?? 0)"
        lblTime.text = Utils.getDaysAgo(postDate: data.creation_date_time)
        let likeCount = data.post_likes?.filter({ like in
            Utils.getUser(user_id: like.user_id)?.is_deleted ?? false ==  false
        }).count
        lblLikeCount.text = "\(likeCount ?? 0)"
        lblDislikeCount.text = "\(data.dislike_count ?? 0)"
        let commentCount = data.comments?.filter({ comment in
            Utils.getUser(user_id: comment.user_id)?.is_deleted ?? false ==  false
        }).count
        lblCommentCount.text = "\(commentCount ?? 0)"
        lblCommentsText.text = (data.comments?.count ?? 0) == 0 ? "No Comments" : "View all \(commentCount ?? 0) comments"
        if (data.comments?.count ?? 0) > 0{
            lblFirstComment.text = data.comments?[0].comment_text
        }else{
            lblFirstComment.text = ""
        }
        if (data.image_urls?.count ?? 0) > 1{
            pageControl.isHidden = false
            pageControlHeight.constant = 60
        }else{
            pageControl.isHidden = true
            pageControlHeight.constant = 14
        }
        pageControl.numberOfPages = data.image_urls?.count ?? 0
        let alreadyLiked = data.post_likes?.contains(where: { postLike in
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
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        if posts != nil{
            delegate?.moreClicked(index: index,post: posts!)
        }
    }
    @IBAction func likePostButtonPressed(_ sender: Any) {
        print(index)
        
        Utils.logFirebaseEvent(eventName: "like_post")
        let alreadyLiked = posts?.post_likes?.contains(where: { postLike in
            postLike.user_id == Auth.auth().currentUser?.uid ?? ""
        })
        if alreadyLiked ?? false{
            likeIcon.image = UIImage(named: "likeIcon")
            likeIcon.tintColor = UIColor.red
            
        }else{
            if posts?.user_id != Auth.auth().currentUser?.uid ?? "" {
                Utils.addNotification(user_id: posts?.user_id ?? "", post_id: posts?.post_id ?? "", event: .like)
                if let user = Utils.getUser(user_id: posts?.user_id ?? ""){
                    Utils.sendNotification(fcm: user.fcm ?? "", event: .like,user: user,name: Auth.auth().currentUser?.displayName ?? "",post_id: posts?.post_id ?? "" , user_id: posts?.user_id ?? "")
                }
            }
            likeIcon.image = UIImage(named: "dislikeIcon")
            likeIcon.tintColor = UIColor.black
        }
        delegate?.likePost(post: &posts!, index: index)
    }
    @IBAction func dislikeButtonPressed(_ sender: Any) {
        delegate?.dislikePost(post: &posts!,index: index)
    }
    @IBAction func commentButtonPressed(_ sender: Any) {
        delegate?.commentOnPost(post: &posts!,index: index)
        Utils.logFirebaseEvent(eventName: "comment_post")
    }
    @IBAction func shareButtonPressed(_ sender: Any) {
        delegate?.sharePost(post: posts!)
        Utils.logFirebaseEvent(eventName: "share_post")
    }
    @IBAction func viewAllComments(_ sender: Any) {
        if (posts?.comment_count ?? 0) > 0{
            delegate?.viewAllComments(post: posts!, index: index)
        }
    }
    @IBAction func profileButtonTapped(_ sender: Any) {
        self.delegate?.openProfile(post: posts!, index: index)
    }
}

extension HomeFeedTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts?.image_urls?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FeedPhotosCollectionViewCell.self), for: indexPath) as? FeedPhotosCollectionViewCell else { return UICollectionViewCell() }
        if (posts?.image_urls?.count ?? 0) > 0{
            if posts?.image_urls?[indexPath.item].contains("post_images") ?? false{
                cell.playView.isHidden = true
                Utils.loadImage(imageView: cell.feedImageView, urlString: (posts?.image_urls?[indexPath.item] ?? ""), placeHolder: UIImage(named: "placeholderImage"))
            }else{
                cell.playView.isHidden = false
                cell.feedImageView.image = UIImage(named: "placeholderImage")
                DispatchQueue.global(qos: .background).async {[self] in
                    guard let url = URL(string: posts?.image_urls?[indexPath.item] ?? "") else { return }
                    createVideoThumbnail(from: url, completion: { image in
                        DispatchQueue.main.async {
                            cell.feedImageView.image = image
                        }
                    })
                }
            }
            
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.bounds.width, height: 378)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = pageIndex
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.openFullScreenVideoImage(url: posts?.image_urls?[indexPath.item] ?? "")
    }
}

extension HomeFeedTableViewCell{
    func createVideoThumbnail(from url: URL,completion: (UIImage) -> Void){
        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.maximumSize = CGSize(width: frame.width, height: frame.height)
        
        let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            completion(thumbnail)
        }
        catch {
            print(error.localizedDescription)
            return
        }
    }
    func addAttributedName(label: UILabel, name: String, tag: String? = nil){
        let tagged = "tagged \(tag ?? "")"
        let attributedText = NSMutableAttributedString(string: "\(name) \(tag == nil ? "" : tagged)")
        
        // Set bold font for "Ehtisham Badar" using attributes dictionary
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.satoshiMedium(withSize: 16)!, // Adjust the font size as needed
            .foregroundColor: self.isDarkModeEnabled() ? UIColor.white : UIColor.labelColor! // Adjust the color as needed
        ]
        attributedText.setAttributes(boldAttributes, range: (attributedText.string as NSString).range(of: name))
        
        // Set bold font for "Lahore" using attributes dictionary
        attributedText.setAttributes(boldAttributes, range: (attributedText.string as NSString).range(of: tag ?? ""))
        
        label.attributedText = attributedText
        
    }
}
extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        guard let attributedText = label.attributedText else {
            return false
        }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y)
        
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                            in: textContainer,
                                                            fractionOfDistanceBetweenInsertionPoints: nil)
        
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
