//
//  SendPhotoVideoViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 11/06/2023.
//

import UIKit
import AVKit
import AVFoundation

protocol SendPhotoVideoViewControllerDelegate{
    func sendPhoto(image: UIImage)
    func sendVideo(url: URL)
}

class SendPhotoVideoViewController: BaseViewController {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var blurView: UIView!
    
    var image: UIImage?
    var url: URL?
    
    var delegate: SendPhotoVideoViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        if url == nil {
            imgView.image = image
        }else{
            self.imgView.image = UIImage(named: "placeholderImage")
            generateThumbnailImage(from: url!) { image in
                DispatchQueue.main.async {
                    self.imgView.image = image
                }
                
            }
        }
    }
    @IBAction func playVideoButton(_ sender: Any) {
        if url != nil{
            self.playVideo(url: url!)
        }
    }
    @IBAction func sendImageButtonPressed(_ sender: Any) {
        self.dismiss(animated: true) {[self] in
            if url == nil{
                self.delegate?.sendPhoto(image: self.image ?? UIImage())
            }else{
                self.delegate?.sendVideo(url: url!)
            }
            
        }
        
    }

    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    func generateThumbnailImage(from videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60) // Capture the thumbnail at 1 second
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { (_, thumbnailCGImage, _, _, _) in
            if let thumbnailCGImage = thumbnailCGImage {
                let thumbnailImage = UIImage(cgImage: thumbnailCGImage)
                completion(thumbnailImage)
            } else {
                completion(nil)
            }
        }
    }
}
