//
//  FullScreenPhotoViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 16/04/2023.
//

import UIKit

class FullScreenPhotoViewController: UIViewController {

    @IBOutlet weak var imageview: UIImageView!
    var imageurl = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.loadImage(imageView: imageview, urlString: imageurl, placeHolder: UIImage(named: "placeholderImage"))
        
        self.logPageView()
    }
    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
