//
//  ChangePasswordViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 21/06/2023.
//

import UIKit
import FirebaseAuth

class ChangePasswordViewController: BaseViewController {
    
    @IBOutlet weak var confirmPassTF: UITextField!
    @IBOutlet weak var newPassTF: UITextField!
    @IBOutlet weak var oldPassTF: UITextField!
    @IBOutlet weak var oldView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if checkProvider() == .auth{
            oldView.isHidden = false
        }else{
            oldView.isHidden = true
        }
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    func checkPassword(password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: Utils.user?.email ?? "", password: password) { (_, error) in
            if error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    @IBAction func updatePassButtonPressed(_ sender: Any) {
        self.startLoader()
        if oldPassTF.text == "" && checkProvider() == .auth{
            self.stopLoader()
            self.alert(title: "Alert", message: "Enter Old Password")
            return
        }
        if checkProvider() == .auth{
            checkPassword(password: oldPassTF.text ?? "", completion: { [self] correct in
                if correct {
                    verify()
                }else{
                    self.alert(title: "Alert", message: "Old Password is not correct")
                    self.stopLoader()
                }
            })
        }else{
            verify()
        }
        
    }
    func verify(){
        if newPassTF.text == "" {
            self.stopLoader()
            self.alert(title: "Alert", message: "Enter Password")
            return
        }
        if confirmPassTF.text == "" {
            self.stopLoader()
            self.alert(title: "Alert", message: "Enter Confirm Password")
            return
        }
        if confirmPassTF.text != newPassTF.text{
            self.stopLoader()
            self.alert(title: "Alert", message: "Passwords doesn't matched")
            return
        }
        guard let currentUser = Auth.auth().currentUser else { return }
        currentUser.updatePassword(to: newPassTF.text ?? "") { error in
            if error == nil{
                self.stopLoader()
                self.navigationController?.popViewController(animated: true)
                self.alert(title: "Success", message: "Password Updated")
                Utils.logFirebaseEvent(eventName: "change_password")
            }else{
                self.alert(title: "Alert", message: "Please Login again to continue.")
                self.stopLoader()
            }
        }
    }
}
extension UIViewController{
    func checkProvider() -> Provider{
        if let user = Auth.auth().currentUser {
            for userInfo in user.providerData {
                let providerID = userInfo.providerID
                if providerID == "google.com" {
                    return .google
                } else if providerID == "apple.com" {
                    return .apple
                } else if providerID == "password" {
                    return .auth
                } else {
                    return .facebook
                }
            }
        } else {
            return .none
        }
        return .none
    }
}

enum Provider {
    case google
    case facebook
    case apple
    case auth
    case none
}
