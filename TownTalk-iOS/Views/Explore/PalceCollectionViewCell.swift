//
//  PalceCollectionViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/03/2023.
//

import UIKit

class PalceCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var hotspotView: UIView!
    @IBOutlet weak var openNowView: UIView!
    @IBOutlet weak var placeImgView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setCell(data: CheckIn){
        lblAddress.text = data.place_address
        lblName.text = data.place_name
        Utils.loadImage(imageView: placeImgView, urlString: data.place_photo ?? "", placeHolder: UIImage(named: "placeholderImage"))
        openNowView.isHidden = !(data.open_now ?? true)
    }

}
