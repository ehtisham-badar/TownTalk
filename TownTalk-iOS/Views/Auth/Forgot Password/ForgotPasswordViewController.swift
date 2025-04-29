//
//  ForgotPasswordViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 12/07/2023.
//

import UIKit
import FirebaseAuth

class ForgotPasswordViewController: BaseViewController {
    
    @IBOutlet weak var emailTF: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func resetPressed(_ sender: Any) {
        if emailTF.text == ""{
            self.alert(title: "Alert", message: "Email can't be empty.")
            return
        }
        self.startLoader()
        resetPassword(email: emailTF.text ?? "") { error in
            if let error = error {
                print("Password reset failed: \(error.localizedDescription)")
                self.stopLoader()
            } else {
                self.stopLoader()
                self.alert(title: "Success", message: "Check your email to reset your password")
            }
        }
    }
    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            completion(error)
        }
    }
}
