//
//  NotificationTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit

protocol NotificationTableViewCellDelegate{
    func openProfile(user_id: String,index: Int)
}

class NotificationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var notificationText: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    
    var delegate: NotificationTableViewCellDelegate?
    var user = User(profile_pic: "", username: "", email: "", phone: "", zip_code: "")
    var notification: AppNotification?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    @IBOutlet weak var lblTie: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    func setTraits(){
        if self.isDarkModeEnabled(){
            imgView.borderColor = UIColor.white
            imgView.borderWidth = 1.0
        }else{
            imgView.borderColor = UIColor.clear
        }
    }
    @IBAction func openProfileButtonPressed(_ sender: Any) {
        delegate?.openProfile(user_id: self.notification?.user_id ?? "",index: imgView.tag)
    }
    func setCell(data: AppNotification){
        setTraits()
        self.notification = data
        self.contentView.backgroundColor = (data.is_read) ? UIColor.clear : self.isDarkModeEnabled() ? UIColor.lightGray : UIColor.notificationReadColor
        print("user id = \(data.user_id ?? "")")
        self.user = Utils.getUser(user_id: data.user_id ?? "") ?? User(profile_pic: "", username: "", email: "", phone: "", zip_code: "", fullName: "", feeds: nil, isSelected: nil, bio: nil, city: nil, uid: "", cityLat: nil, cityLng: nil, checked_in_time: nil, is_deleted: nil)
        lblTie.text = Utils.formatTime(inputTime: data.time ?? "")
        Utils.loadImage(imageView: imgView, urlString: self.user.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
        let username = (self.user.fullName == "" || self.user.fullName == nil) ? self.user.username : self.user.fullName
        switch data.event{
        case EventNotification.like.rawValue:
            notificationText.text = "\(username ?? "") liked your post, view Now"
        case EventNotification.comment.rawValue:
            notificationText.text = "\(username ?? "") commented on your post, view Now"
        case EventNotification.comment_like.rawValue:
            notificationText.text = "\(username ?? "") liked your comment, view Now"
        case EventNotification.comment_mention.rawValue:
            notificationText.text = "\(username ?? "") mentioned you in a comment, view Now"
        case EventNotification.post_tag.rawValue:
            notificationText.text = "\(username ?? "") tagged you in a post, view Now"
        default:
            break
        }
    }
    
}
