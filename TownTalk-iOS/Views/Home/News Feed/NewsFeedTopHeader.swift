//
//  NewsFeedTopHeader.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/03/2023.
//

import UIKit
import FirebaseAuth

protocol NewsFeedTopHeaderDelegate{
    func clossSheet()
    func searchPressed()
    func notificationPressed()
    func editPressed()
    func allNewsFeed()
}

class NewsFeedTopHeader: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    var delegate: NewsFeedTopHeaderDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        lblName.text = "Hello, \(Auth.auth().currentUser?.displayName ?? Utils.user?.fullName ?? "")!"
        Utils.loadImage(imageView: profileImage, urlString: Auth.auth().currentUser?.photoURL?.absoluteString ?? "" , placeHolder: UIImage(named: "placeholder"))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func crossPressed(_ sender: Any) {
        delegate?.clossSheet()
    }
    @IBAction func searchButtonPressed(_ sender: Any) {
        delegate?.searchPressed()
    }
    @IBAction func notificationButtonPressed(_ sender: Any) {
        delegate?.notificationPressed()
    }
    @IBAction func editButtonPressed(_ sender: Any) {
        delegate?.editPressed()
    }
    @IBAction func allNewsFeedButtonPressed(_ sender: Any) {
        delegate?.allNewsFeed()
    }
}
