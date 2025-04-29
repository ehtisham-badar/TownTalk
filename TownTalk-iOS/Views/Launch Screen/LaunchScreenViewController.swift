//
//  LaunchScreenViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit
import FirebaseAuth

class LaunchScreenViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isDarkModeEnabled(){
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.overrideUserInterfaceStyle = .dark
        }else{
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.overrideUserInterfaceStyle = .light
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
            if Auth.auth().currentUser == nil {
                let storyboard = UIStoryboard(name: "Auth", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: LoginViewController.self)) as! LoginViewController
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                let storyboard = UIStoryboard(name: "Home", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: TabBarController.self)) as! TabBarController
                self.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
}
