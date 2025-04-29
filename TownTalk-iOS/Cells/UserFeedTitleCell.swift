//
//  UserFeedTitleCell.swift
//  TownTalk-iOS
//
//  Created by Abdul Moiz on 9/2/23.
//

import UIKit

class UserFeedTitleCell: UITableViewCell {
    
    
    @IBOutlet weak var main_view: UIView!
    @IBOutlet weak var create_NewFeed: UIButton!
    @IBOutlet weak var addUserToFeed: UIButton!
    @IBOutlet weak var titleFeed: UILabel!

    var createNewFeed_tap:(()->Void)? = nil
    var addUserToFeed_tap:(()->Void)? = nil

    
    
    


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    @IBAction func createNewFeedButtonPressed(_ sender: Any) {
        createNewFeed_tap?()
    }
    
    @IBAction func addUserToFeedButtonPressed(_ sender: Any) {
        addUserToFeed_tap?()
    }

}
