//
//  CreateNewsFeedViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit

protocol CreateNewsFeedViewControllerDelegate {
    func feedCreated()
}

class CreateNewsFeedViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var feedTF: UITextField!
    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    
    var delegate: CreateNewsFeedViewControllerDelegate?
    var feeds = [Feed]()
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        feedTF.delegate = self
        
        self.logPageView()
    }
    
    deinit {
        removeObservers()
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
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func createButtonPressed(_ sender: Any) {
        guard feedTF.text != "" else {
            self.alert(title: "Alert", message: "Enter a News Feed Name")
            return
        }
        for i in 0..<feeds.count{
            if feeds[i].feed_name == feedTF.text ?? ""{
                self.alert(title: "Duplicate", message: "Feed Name already exists")
                return
            }
        }
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SendRequestViewController.self)) as! SendRequestViewController
        vc.feedName = feedTF.text ?? ""
        vc.feeds = self.feeds
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension CreateNewsFeedViewController: SendRequestViewControllerDelegate {
    func feedUpdated() {
        
    }
    
    func feedCreated1() {
        
    }
    
    func feedCreated() {
        delegate?.feedCreated()
    }
}
