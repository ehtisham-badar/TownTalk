//
//  SettingViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase

class SettingViewController: BaseViewController {
    
    @IBOutlet weak var lightIcon: UIImageView!
    @IBOutlet weak var darkIcon: UIImageView!
    @IBOutlet weak var lightModeView: UIView!
    @IBOutlet weak var darkModeView: UIView!
    @IBOutlet weak var tableView: UITableView!
    let titleArray = ["Blocked Users", "Push Notifications", "Change password", "Privacy Policy", "Terms of Service", "EULA","Help Center", "Community Guidelines" , "Contact us", "Delete account","Logout" ]  //, "Switch Account"
    let subArray = ["Managed people blocked", "Manage notifications preference", "Manage your account password", "Read our privacy policy", "Read our terms and conditions", "Read End-User License Agreement","View Town Talk Help Center", "Read our community guidelines" ,"We will love to hear from you", "You wont be able to recovered the account", "You will be missed" ] //, "Change Account With App"
    let imageArray = ["blockUserIcon", "pushNotiIcon", "changePassIcon","privacyIcon","termsIcon","eulaIcon","eulaIcon","eulaIcon" ,"contactUsIcon", "deleteAccIcon","logoutIcon" ]
   // , "switch"
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        if self.isDarkModeEnabled(){
            darkModeView.backgroundColor = UIColor.labelColor
            lightModeView.backgroundColor = UIColor.clear
            darkIcon.tintColor = UIColor.white
            lightIcon.tintColor = UIColor.labelColor
        }else{
            darkModeView.backgroundColor = UIColor.clear
            lightModeView.backgroundColor = UIColor.labelColor
            darkIcon.tintColor = UIColor.labelColor
            lightIcon.tintColor = UIColor.white
        }
    }
    
    private func setView(){
        registerNibs()
    }
    private func registerNibs(){
        tableView.register(UINib(nibName: String(describing: SettingsTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: SettingsTableViewCell.self))
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func darkModeButtonPressed(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "darkmode")
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        window?.overrideUserInterfaceStyle = .dark
        darkModeView.backgroundColor = UIColor.labelColor
        lightModeView.backgroundColor = UIColor.clear
        darkIcon.tintColor = UIColor.white
        lightIcon.tintColor = UIColor.labelColor
        
        Utils.logFirebaseEvent(eventName: "set_dark_mode")
    }
    @IBAction func lighModeButtonPressed(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "darkmode")
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        window?.overrideUserInterfaceStyle = .light
        darkModeView.backgroundColor = UIColor.clear
        lightModeView.backgroundColor = UIColor.labelColor
        darkIcon.tintColor = UIColor.labelColor
        lightIcon.tintColor = UIColor.white
        
        Utils.logFirebaseEvent(eventName: "set_light_mode")
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsTableViewCell.self)) as? SettingsTableViewCell else { return UITableViewCell() }
        cell.lblTitle.text = titleArray[indexPath.row]
        cell.lblSubtitle.text = subArray[indexPath.row]
        cell.settingIcon.image = UIImage(named: imageArray[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            let storyboard = UIStoryboard(name: "Setting", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: BlockUsersViewController.self)) as! BlockUsersViewController
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 1{
            let alertController = UIAlertController(title: "Push Notifications", message: "What to you want to do?", preferredStyle: .alert)
            let isEnable = UserDefaults.standard.bool(forKey: "pushNotifications")
            let action1 = UIAlertAction(title: isEnable ? "Disable" : "Enable", style: .default) { (_) in
                UserDefaults.standard.set(!isEnable, forKey: "pushNotifications")
                
                Utils.logFirebaseEvent(eventName: "\(!isEnable ? "Disable" : "Enable")_notification")
            }
            let action2 = UIAlertAction(title: "Cancel", style: .destructive) { (_) in
                
            }
            alertController.addAction(action1)
            alertController.addAction(action2)
            self.present(alertController, animated: true, completion: nil)
        }
        if indexPath.row == 2{
            let storyboard = UIStoryboard(name: "Auth", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ChangePasswordViewController.self)) as! ChangePasswordViewController
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 3{
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
            vc.name = titleArray[indexPath.row]
            vc.url = "https://app.termly.io/document/privacy-policy/72c48b63-dcc9-42ea-9088-7663a09410d7"
            self.navigationController?.pushViewController(vc, animated: true)
            Utils.logFirebaseEvent(eventName: "get_privacy_policy")
        }
        if indexPath.row == 4{
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
            vc.name = titleArray[indexPath.row]
            vc.url = "https://app.termly.io/document/terms-of-service/337641ae-e6ce-4fed-8267-c8105baa3a0f"
            self.navigationController?.pushViewController(vc, animated: true)
            Utils.logFirebaseEvent(eventName: "get_terms_of_use")
        }
        if indexPath.row == 5{
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
            vc.name = titleArray[indexPath.row]
            vc.url = "https://app.termly.io/document/eula/847f5351-bd4a-461e-a246-97743430a237"
            self.navigationController?.pushViewController(vc, animated: true)
            Utils.logFirebaseEvent(eventName: "get_EULA")
        }
        if indexPath.row == 6{
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
            vc.name = titleArray[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
            Utils.logFirebaseEvent(eventName: "get_help_center")
        }
        if indexPath.row == 7{
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
            vc.name = titleArray[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
            Utils.logFirebaseEvent(eventName: "get_community_guidelines")
        }
        if indexPath.row == 8{
            let storyboard = UIStoryboard(name: "Popups", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ContactSupportViewController.self)) as! ContactSupportViewController
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true)
            Utils.logFirebaseEvent(eventName: "get_\(titleArray[indexPath.row])")
            
        }
        if indexPath.row == 9{
            deleteAccount()
        }
        
        if indexPath.row == titleArray.count-1  {
            let alertController = UIAlertController(title: "Logout", message: "Are you sure you wanna logout?", preferredStyle: .alert)
            let action1 = UIAlertAction(title: "Yes", style: .default) { (_) in
                try! Auth.auth().signOut()
                Utils.logFirebaseEvent(eventName: "signOut")
                let loginViewController = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: String(describing: MainNavigationViewController.self))
                UIApplication.shared.keyWindow?.rootViewController = loginViewController
                return
                
            }
            
            let action2 = UIAlertAction(title: "No", style: .destructive) { (_) in
                
            }
            alertController.addAction(action1)
            alertController.addAction(action2)
            self.present(alertController, animated: true, completion: nil)
        }
        
        
//        if indexPath.row == titleArray.count-1 {
//            debugPrint("Switch Account...")
//            let storyboard = UIStoryboard(name: "Setting", bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SwitchAccountViewController.self)) as! SwitchAccountViewController
//            vc.modalTransitionStyle = .coverVertical
//            self.present(vc, animated: true)
//            }
        
        
        
        
        
    }
    func deleteAccount(){
        let alertController = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account?", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.deleteFromAuthentication()
        }
        let action2 = UIAlertAction(title: "No", style: .destructive) { (_) in
            
        }
        alertController.addAction(action1)
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
    }
    func deleteFromAuthentication(){
        self.startLoader()
        if let user = Auth.auth().currentUser {
            user.delete { error in
                if let error = error {
                    print("Error deleting user account: \(error.localizedDescription)")
                } else {
                    print("User account deleted successfully")
                }
            }
        }
        Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").updateChildValues(["is_deleted": true]) { error, ref in
            try! Auth.auth().signOut()
            Utils.logFirebaseEvent(eventName: "delete_user_account")
            let loginViewController = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: String(describing: MainNavigationViewController.self))
            UIApplication.shared.keyWindow?.rootViewController = loginViewController
        }
    }
}
