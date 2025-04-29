//
//  UserAccountCell.swift
//  TownTalk-iOS
//
//  Created by Veripark on 08/09/2023.
//

import UIKit

class UserAccountCell: UITableViewCell {

    @IBOutlet weak var main_view: UIView!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var udid: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
