//
//  ReceiveImageTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 16/05/2023.
//

import UIKit

class ReceiveImageTableViewCell: UITableViewCell {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var reactionView: UIView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var messageImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
