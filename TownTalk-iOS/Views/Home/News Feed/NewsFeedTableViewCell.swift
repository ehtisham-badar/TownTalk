//
//  NewsFeedTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/03/2023.
//

import UIKit

protocol NewsFeedTableViewCellDelegate{
    func addUsers(feed: Feed)
    func moreOptionsSelected(feed: Feed, index: Int)
}

class NewsFeedTableViewCell: UITableViewCell {

    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var addUserBtn: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    
    var delegate: NewsFeedTableViewCellDelegate?
    var feed: Feed?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func addUserPressed(_ sender: Any) {
        delegate?.addUsers(feed: self.feed!)
    }
    
    @IBAction func morePressed(_ sender: Any) {
        delegate?.moreOptionsSelected(feed: feed!, index: moreBtn.tag)
    }
}
