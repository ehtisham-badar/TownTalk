//
//  TagBusinessTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 21/06/2023.
//

import UIKit

class TagBusinessTableViewCell: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populateData(data: Location) {
        lblName.text = data.main_text
        lblAddress.text = data.secondary_text
    }
}
