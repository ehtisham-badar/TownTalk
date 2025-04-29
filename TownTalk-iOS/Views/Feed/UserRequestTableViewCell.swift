//
//  UserRequestTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit

class UserRequestTableViewCell: UITableViewCell {

    @IBOutlet weak var selectIcon: UIImageView!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
