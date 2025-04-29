//
//  ReviewCollectionViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit

class ReviewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var reviewCount: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblReview: UILabel!
    
    func populateData(data: Reviews){
        let user = Utils.getUser(user_id: data.user_id ?? "")
        lblName.text = user?.fullName == "" ? user?.username ?? "" : user?.fullName ?? ""
        Utils.loadImage(imageView: profileImage, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
        reviewCount.text = "\(data.review_count ?? 0.0)"
        lblReview.text = data.review_text
    }
}
