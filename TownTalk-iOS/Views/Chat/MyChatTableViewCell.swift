//
//  MyChatTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit

protocol MyChatTableViewCellDelegate{
    func openUserProfile(index: Int)
    func unblockUser(index: Int)
}
extension MyChatTableViewCellDelegate{
    func unblockUser(index: Int){
        
    }
    func openUserProfile(index: Int){
        
    }
}

class MyChatTableViewCell: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var unblockbtn: UIButton!
    
    var delegate: MyChatTableViewCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func unblockButtonPressed(_ sender: Any) {
        delegate?.unblockUser(index: unblockbtn.tag)
    }
    func setUserCells(user: User){
        if user.fullName == "" || user.fullName == " "{
            lblName.text = user.username
        }else{
            lblName.text = user.fullName
        }
        lblMessage.text = "@\(user.username ?? "")"
        lblTime.isHidden = true
        Utils.loadImage(imageView: profileImage, urlString: user.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
    }
    
    func setupUser(data: Chat,isGroup: Bool){
        if isGroup{
            lblName.text = data.group_name ?? ""
            lblMessage.text = data.last_message ?? ""
            Utils.loadImage(imageView: profileImage, urlString: data.group_image ?? "", placeHolder: UIImage(named: "placeholder"))
            lblTime.text = Utils.getDaysAgo(postDate: data.time ?? "")
        }else{
            let user = Utils.getUser(user_id: data.user?.uid ?? "")
            lblName.text = (user?.fullName == "" || user?.fullName == nil) ? user?.username : user?.fullName
            lblMessage.text = data.last_message ?? ""
            Utils.loadImage(imageView: profileImage, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
            lblTime.text = Utils.getDaysAgo(postDate: data.time ?? "")
        }
    }
    @IBAction func openProfile(_ sender: Any) {
        delegate?.openUserProfile(index: button.tag)
    }
    
}
