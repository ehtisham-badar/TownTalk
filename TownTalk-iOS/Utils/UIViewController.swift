//
//  Login.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//

import Foundation
import UIKit
extension UIViewController{
    func clearNavigationBackground(){
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    func resetNavigationBackground(){
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
}


extension UIViewController{
    func alert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
