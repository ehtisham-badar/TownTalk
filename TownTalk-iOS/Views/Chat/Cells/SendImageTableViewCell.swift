//
//  SendImageTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 16/05/2023.
//

import UIKit

class SendImageTableViewCell: UITableViewCell {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var reactionView: UIView!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var messageImage: UIImageView!
    @IBOutlet weak var lblTime: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
