//
//  ZodiacSignCell.swift
//  TownTalk-iOS
//
//  Created by Veripark on 10/09/2023.
//

import UIKit

class ZodiacSignCell: UITableViewCell {
    
    @IBOutlet weak var zodiacSignTitle: UILabel!
    @IBOutlet weak var zodiacSignCheck: UIImageView!



    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
