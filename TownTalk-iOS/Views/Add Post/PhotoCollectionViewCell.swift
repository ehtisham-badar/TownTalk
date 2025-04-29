//
//  PhotoCollectionViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 31/03/2023.
//

import UIKit

protocol PhotoCollectionViewCellDelegate{
    func deleteImage(index: Int,postid: String)
}

class PhotoCollectionViewCell: UICollectionViewCell {
    
    var delegate: PhotoCollectionViewCellDelegate?
    var postid = ""
    
    @IBOutlet weak var crossbtn: UIButton!
    @IBOutlet weak var photoImageView: UIImageView!
    
    @IBAction func crossButtonPressed(_ sender: Any) {
        delegate?.deleteImage(index: crossbtn.tag,postid: postid)
    }
}
