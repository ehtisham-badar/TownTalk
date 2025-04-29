//
//  ReplyTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 04/04/2023.
//

import UIKit

protocol ReplyTableViewCellDelegate{
    func morePress(index: Int)
    func likePress(index: Int)
}

class ReplyTableViewCell: UITableViewCell {

    @IBOutlet weak var replierPhoto: UIImageView!
    @IBOutlet weak var replierName: UILabel!
    @IBOutlet weak var reply: UILabel!
    @IBOutlet weak var moreIcon: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    
    var delegate: ReplyTableViewCellDelegate?
    var index: Int = 0
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func morePressed(_ sender: Any) {
        delegate?.morePress(index: index)
    }
    @IBAction func likeButtonPressed(_ sender: Any) {
        delegate?.likePress(index: index)
    }
}
