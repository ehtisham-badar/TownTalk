//
//  TagUserTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 14/06/2023.
//

import UIKit

class TagUserTableViewCell: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
