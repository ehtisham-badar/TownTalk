//
//  PhotoPicker.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//

import UIKit
import CropViewController
import AVFoundation

protocol PhotoPickerDelegate {
    func didFinish(image: UIImage)
}

class PhotoPicker:NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate{
    
    static let shared = PhotoPicker()
    private var callingController: UIViewController!
    var delegate: PhotoPickerDelegate?
    
    func pickPhoto(with: UIViewController){
        callingController = with
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // create an action
        let firstAction: UIAlertAction = UIAlertAction(title: "Camera", style: .default) { action -> Void in
            self.countineIfCameraPermissionAlow()
        }
        
        let secondAction: UIAlertAction = UIAlertAction(title: "Photo Library", style: .default) { action -> Void in
            
            self.openPicker(sourceType: .savedPhotosAlbum)
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
        
        // add actions
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(secondAction)
        actionSheetController.addAction(cancelAction)
        
        
        if let popoverController = actionSheetController.popoverPresentationController {
            popoverController.sourceView = with.view
            popoverController.sourceRect = CGRect(x: with.view.bounds.midX, y: with.view.bounds.height, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // present an actionSheet...
        callingController.present(actionSheetController, animated: true, completion: nil)
    }
    func capturePhoto(with: UIViewController){
        callingController = with
        self.countineIfCameraPermissionAlow()
    }
    
    private func countineIfCameraPermissionAlow(){
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            self.openPicker(sourceType: .camera)
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    self.openPicker(sourceType: .camera)
                } else {
                    let getCameraPermsiionAlert = UIAlertController(title: nil, message: Constants.APP_NAME + " would like to access your camera in order to take picture.", preferredStyle: .alert)
                    let cancelAction = UIAlertAction.init(title: "Skip", style: .default, handler: { (action) in
                        getCameraPermsiionAlert.dismiss(animated: true)
                    })
                    
                    let yesAction = UIAlertAction.init(title: "Settings", style: .default, handler: { (action) in
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
                        } else {
                            // Fallback on earlier versions
                        }
                    })
                    
                    getCameraPermsiionAlert.addAction(cancelAction)
                    getCameraPermsiionAlert.addAction(yesAction)
                    getCameraPermsiionAlert.preferredAction = yesAction
                    
                    self.callingController.present(getCameraPermsiionAlert, animated: true, completion: nil)
                }
            })
        }
    }
    
    private func openPicker(sourceType: UIImagePickerController.SourceType){
        DispatchQueue.main.async {
            let imagePicker = UIImagePickerController.init()
            imagePicker.navigationBar.tintColor = .black
            //        imagePicker.allowsEditing = true
            imagePicker.delegate = self
            imagePicker.sourceType = sourceType
            self.callingController.present(imagePicker, animated: true, completion: nil)
        }
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        let image = info["UIImagePickerControllerOriginalImage"] as! UIImage
        let cropViewController = CropViewController(image: image)
        cropViewController.delegate = self
        picker.dismiss(animated: false, completion: nil)
        self.callingController.present(cropViewController, animated: false, completion: nil)
    }
    //    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    //        // Local variable inserted by Swift 4.2 migrator.
    //        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
    //
    //        let image = info["UIImagePickerControllerOriginalImage"] as! UIImage
    //        let cropViewController = CropViewController(image: image)
    //        cropViewController.delegate = self
    //		self.delegate?.didFinish(image: image)
    //        picker.dismiss(animated: false, completion: nil)
    //        self.callingController.present(cropViewController, animated: false, completion: nil)
    //    }
    
    func cropViewController(_ cropViewController: CropViewController,
                            didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        cropViewController.dismiss(animated: true) {
            DispatchQueue.main.async {
                self.delegate?.didFinish(image: image)
            }
        }
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

