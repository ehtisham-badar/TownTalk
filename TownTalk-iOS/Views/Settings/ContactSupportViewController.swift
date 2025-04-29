//
//  ContactSupportViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 02/07/2023.
//

import UIKit
import MessageUI

class ContactSupportViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var mainView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        
        self.logPageView()
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
    @IBAction func supportButtonPressed(_ sender: Any) {
        sendEmail(email: "support@towntalkapp.com", text: "I Need Support")
    }
    @IBAction func legalButtonPressed(_ sender: Any) {
        sendEmail(email: "legal@towntalkapp.com", text: "Legal")
    }
    @IBAction func businessButtonPressed(_ sender: Any) {
        sendEmail(email: "business@towntalkapp.com", text: "Business/Partnerships ")
    }
    func sendEmail(email:String,text: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email])
            mail.setMessageBody("<p>\(text)!</p>", isHTML: true)
            
            present(mail, animated: true)
        } else {
            
        }
    }
}
