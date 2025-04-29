//
//  PlaceTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 04/06/2023.
//

import UIKit

class PlaceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var openNowView: UIView!
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblPlaceName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func populateData(data: ShoppingPlace){
        lblPlaceName.text = data.name
        lblAddress.text = data.address
        Utils.loadImage(imageView: placeImage, urlString: data.photo, placeHolder: UIImage(named: "placeholderImage"))
        openNowView.isHidden = !data.openNow
    }
    func setCell(data: CheckIn){
        lblPlaceName.text = data.place_name
        lblAddress.text = data.place_address
        Utils.loadImage(imageView: placeImage, urlString: data.place_photo ?? "", placeHolder: UIImage(named: "placeholderImage"))
        openNowView.isHidden = !(data.open_now ?? true)
    }
    
}
