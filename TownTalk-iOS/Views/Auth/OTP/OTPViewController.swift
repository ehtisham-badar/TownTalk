//
//  OTPViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 21/03/2023.
//

import UIKit
import FirebaseAuth
import MBProgressHUD
import DPOTPView

class OTPViewController: BaseViewController {
    
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var continueBtnBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var otpTextField: DPOTPView!
    var otpCode = ""
    var email = ""
    var password = ""
    var phone = ""
    var username = ""
    var image: UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        lblDesc.text = "Enter the code we’ve sent to \(self.email)"
    }
    
    deinit {
        removeObservers()
    }
    
    func addObservers(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    func removeObservers(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.continueBtnBottomConstraint.constant = keyboardHeight + 20
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.continueBtnBottomConstraint.constant = 20
        self.view.layoutIfNeeded()
    }
    @IBAction func continuePressed(_ sender: Any) {
        if otpTextField.text == ""{
            self.alert(title: "Alert", message: "Enter OTP.")
            return
        }else if otpTextField.text != self.otpCode{
            self.alert(title: "Alert", message: "Invalid OTP.")
            return
        }else{
            signUPUser()
        }
    }
    func signUPUser(){
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        MBProgressHUD.showAdded(to: self.view, animated: true)
        Utils.logFirebaseEvent(eventName: "register_account")
        Auth.auth().createUser(withEmail: self.email, password: self.password) { [weak self] authResult, error in
            guard let `self` = self else { return }
            if error == nil{
                print("user created")
                self.uploadImage(child: "profile_photos", _image: self.image!) { url in
                    self.saveFirebaseData(username: self.username, email: self.email, phone: self.phone, zip: "", photo: url!) { success in
                        if success != nil{
                            MBProgressHUD.hide(for: self.view, animated: true)
                            print("yeah")
                        }
                    }
                }
            }
        }
    }
    func saveFirebaseData(username: String, email: String, phone: String,zip: String, photo: URL, completion: @escaping((_ url: URL?) -> ())){
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        Utils.getAllUsers { users in
            let user = User(profile_pic: photo.absoluteURL.absoluteString, username: username, email: email, phone: phone, zip_code: zip,fullName: "")
            self.saveDataToFirebase(child: "users", model: user) { postid in
                print(postid)
            }
        }
        let createUpdateRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        createUpdateRequest?.photoURL = URL(string: photo.absoluteURL.absoluteString)!
        createUpdateRequest?.displayName = username
        createUpdateRequest?.commitChanges(completion: { error in
            if error == nil{
                self.navigateToHome()
            }else{
                print(error?.localizedDescription ?? "")
            }
        })
    }
    func navigateToHome(){
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: TabBarController.self)) as! TabBarController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
