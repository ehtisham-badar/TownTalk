//
//  SelectLocationTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 03/05/2023.
//

import UIKit

class SelectLocationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblZipCode: UILabel!
    @IBOutlet weak var lbllocation: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    func populateData(data: Location) {
        lblZipCode.isHidden = false
        lbllocation.text = data.main_text
        lblZipCode.text = data.secondary_text
    }
    
}
