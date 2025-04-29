//
//  SearchUserTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit

class SearchUserTableViewCell: UITableViewCell {

    @IBOutlet weak var profileimage: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setTraits(){
        if self.isDarkModeEnabled(){
            profileimage.borderColor = UIColor.white
            profileimage.borderWidth = 1.0
        }else{
            profileimage.borderColor = UIColor.clear
        }
    }
    func setCell(user: User){
        let user = Utils.getUser(user_id: user.uid ?? "")
        lblName.text = (user?.fullName == "" || user?.fullName == nil) ? user?.username ?? "" : user?.fullName ?? ""
        Utils.loadImage(imageView: profileimage, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
        setTraits()
    } 
}

