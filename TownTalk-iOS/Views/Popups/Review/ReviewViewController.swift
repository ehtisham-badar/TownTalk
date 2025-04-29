//
//  ReviewViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit
import Cosmos

protocol ReviewViewControllerDelegate{
    func didGiveReview(rating: Double, review_note: String)
}

class ReviewViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var reviewTV: UITextView!
    @IBOutlet weak var lblRating: UILabel!
    @IBOutlet weak var cosmosView: CosmosView!
    
    var delegate: ReviewViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        self.logPageView()
        addObservers()
        cosmosView.rating = 1.0
        cosmosView.didTouchCosmos = { rating in
            self.lblRating.text = "\(rating)"
        }
        reviewTV.text = "Add a comment"
        reviewTV.textColor = UIColor.lightGray
        reviewTV.delegate = self
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = self.isDarkModeEnabled() ? UIColor.white : UIColor.black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add a comment"
            textView.textColor = UIColor.lightGray
        }
    }
    private func setView(){
        addGesture()
        mainView.cornerRadius = 35
        mainView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    func addGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        blurView.addGestureRecognizer(tap)
    }
    @objc func dismissView(){
        self.dismiss(animated: true)
    }
    @IBAction func leaveReviewButtonPressed(_ sender: Any) {
        if reviewTV.text == "Add a comment"{
            self.alert(title: "Alert", message: "Please add a comment")
            return
        }else if reviewTV.text == ""{
            self.alert(title: "Alert", message: "Please add a comment")
            return
        }
        self.dismiss(animated: true) {
            self.delegate?.didGiveReview(rating: self.cosmosView.rating, review_note: self.reviewTV.text ?? "")
            Utils.logFirebaseEvent(eventName: "review_hotspot")
        }
        
    }
}
extension ReviewViewController{
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
}
