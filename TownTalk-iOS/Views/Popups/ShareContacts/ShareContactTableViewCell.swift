//
//  ShareContactTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit

protocol ShareContactTableViewCellDelegate{
    func sharePost(chat: Chat)
}

class ShareContactTableViewCell: UITableViewCell {

    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    
    var delegate: ShareContactTableViewCellDelegate?
    var chat: Chat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setCell(data: Chat){
        self.chat = data
        print(self.chat.user?.fullName ?? "")
        lblName.text = (data.user?.fullName == "" || data.user?.fullName == nil) ? (data.user?.username ?? "") : (data.user?.fullName ?? "")
        lblUsername.text = "@\(data.user?.username ?? "")"
        Utils.loadImage(imageView: imgView, urlString: data.user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
    }
    @IBAction func shareButtonPressed(_ sender: Any) {
        self.delegate?.sharePost(chat: self.chat)
    }
}
