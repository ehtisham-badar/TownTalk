//
//  CreateGroupViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 13/05/2023.
//

import UIKit

class CreateGroupViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameTF: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        nameTF.delegate = self
    }
    deinit {
        removeObservers()
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        
        let newLength = text.count + string.count - range.length
        return newLength <= 20
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
            self.bottomViewConstraint.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.bottomViewConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
    @IBAction func nextPressed(_ sender: Any) {
        guard nameTF.text != "" else {
            self.alert(title: "Alert", message: "Enter a Group Name")
            return
        }
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: AddUsersViewController.self)) as! AddUsersViewController
        vc.groupName = nameTF.text ?? ""
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
