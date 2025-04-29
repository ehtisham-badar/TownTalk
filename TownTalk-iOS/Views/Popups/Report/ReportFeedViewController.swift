//
//  ReportFeedViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase

class ReportFeedViewController: BaseViewController, UITextViewDelegate {

    @IBOutlet weak var reportTF: UITextView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var heightViewContraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraintToAnimate: NSLayoutConstraint!
    @IBOutlet weak var viewtodismiss: UIView!
    
    var post: Post?
    var user: User?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bottomConstraintToAnimate.constant = -450
        addGesture()
        setView()
        addObservers()
        reportTF.text = "Why do you want to report this post?"
        reportTF.textColor = UIColor.lightGray
        reportTF.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        animatePopup()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Why do you want to report this post?"
            textView.textColor = UIColor.lightGray
        }
    }
    func animatePopup(){
        UIView.animate(withDuration: 2.0, delay: 0.1, usingSpringWithDamping: 0.0, initialSpringVelocity: 0.1, options: .curveEaseIn) {
            self.bottomConstraintToAnimate.constant = 0
        }
    }
    @IBAction func reportButtonPressed(_ sender: Any) {
        
        reportPost(isBlock: false)
    }
    
    func reportPost(isBlock: Bool){
        if reportTF.text == "" || reportTF.text == "Why do you want to report this post?"{
            self.alert(title: "Error", message: "Please add some report text!")
            return
        }
        
        let report = Report(post: self.post, report_by_user: self.user, report_date_time: Utils.getCurrentDateTime(),report_text: reportTF.text ?? "")
        let data = try! FirebaseEncoder().encode(report)
        Database.database().reference().child("reports").child(Auth.auth().currentUser?.uid ?? "").child(post?.post_id ?? "").setValue(data) { error, ref in
            if error == nil{
                
            }
        }
        if isBlock == false{
            NotificationCenter.default.post(Notification(name: Notification.Name("report_post")))
            NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
        }
        self.reportTF.resignFirstResponder()
        self.dismiss(animated: true)
    }
    func blockUser(){
        let data = try! FirebaseEncoder().encode(self.user)
        Database.database().reference().child("blocked_users").child(Auth.auth().currentUser?.uid ?? "").child(post?.user_id ?? "").setValue(data) { error, ref in
            if error == nil{
                
            }
        }
        self.reportTF.resignFirstResponder()
        self.dismiss(animated: true)
    }
    @IBAction func reportAndBlockButtonPressed(_ sender: Any) {
        reportPost(isBlock: true)
        blockUser()
        NotificationCenter.default.post(Notification(name: Notification.Name("block_user")))
        NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
    }
    
    private func setView(){
        mainView.cornerRadius = 35
        mainView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    func addGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(dismissView1))
        viewtodismiss.addGestureRecognizer(tap1)
        blurView.addGestureRecognizer(tap)
    }
    @objc func dismissView(){
        self.dismiss(animated: true)
    }
    @objc func dismissView1(){
        self.reportTF.resignFirstResponder()
    }
}
extension ReportFeedViewController{
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
            self.bottomConstraintToAnimate.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.bottomConstraintToAnimate.constant = 0
        self.view.layoutIfNeeded()
    }
}
