//
//  TrendingTownsTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/03/2023.
//

import UIKit

class TrendingTownsTableViewCell: UITableViewCell {

    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblCheckIns: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
