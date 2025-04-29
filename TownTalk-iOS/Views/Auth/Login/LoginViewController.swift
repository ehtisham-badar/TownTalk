//
//  LoginViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 20/03/2023.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import MBProgressHUD
import GoogleSignIn
import CodableFirebase
import FirebaseStorage
import FirebaseDatabase
import FBSDKLoginKit
import AuthenticationServices
import ReCaptcha

class LoginViewController: BaseViewController {
    
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let facebookLoginButton = FBLoginButton(frame: .zero)
    private let database = Database.database().reference()
    
    let recaptcha = try? ReCaptcha(
        apiKey: "6LctwYYnAAAAAHJ_qF-RbZQ1xvNoHJnXpDOfvG0c",
        baseURL: URL(string: "http://townTalkapp.app")!,
        endpoint: .alternate
    )
    
    var count = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        facebookLoginButton.delegate = self
        facebookLoginButton.isHidden = true
        
        
        
        
        recaptcha?.configureWebView { [weak self] webview in
            webview.frame = self?.view.bounds ?? CGRect.zero
        }
        
//        if let recaptcha = recaptcha {
//            recaptcha.forceVisibleChallenge = true
//        } else {
//            // Handle the case where recaptcha is nil
//        }
        
        
        
       // recaptcha?.forceVisibleChallenge = true
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        if emailTF.text == ""{
            self.alert(title: "Error", message: "Email is Empty")
            
        }else
        if !(Utils.shared.isValidEmail(emailTF.text ?? "")){
            self.alert(title: "Error", message: "Email is Invalid")
        }else
        if passwordTF.text == ""{
            self.alert(title: "Error", message: "Password is Empty")
        }else{
            self.login()

//            self.handleRecapatcha { [weak self] in
//                
//                guard let `self` = self else {
//                    return
//                }
//                
//            }
        }
    }
    
    private func handleRecapatcha(withhAction actiion: @escaping() -> Void) {
        
        recaptcha?.validate(on: view, completion: { [weak self] result in
            
            guard let `self` = self else {
                return
            }
            
            let wv = self.view.subviews.first { subView in
                subView.isKind(of: WKWebView.self)
            }
            wv?.removeFromSuperview()
            
            print(try? result.dematerialize())

            switch result {
                
            case .token(_):
                actiion()
                
            case .error(let error):
                print(error.localizedDescription)
//                self.alert(title: "Error", message: error.localizedDescription)
            }
        })
    }
    
    
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ForgotPasswordViewController.self)) as! ForgotPasswordViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func loginWithPhonePressed(_ sender: Any) {
        
    }
    @IBAction func facebookLoginButtonPressed(_ sender: Any) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
//        handleRecapatcha { [weak self] in
//
//            guard let `self` = self else {
//                return
//            }
            Utils.logFirebaseEvent(eventName: "login_facebook")
            self.facebookLoginButton.sendActions(for: .touchUpInside)
            
        //}
//        self.alert(title: "Alert", message: "In progress")
    }
    @IBAction func googleSigninButtonPressed(_ sender: Any) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        
//        handleRecapatcha { [weak self] in
//
//            guard let `self` = self else {
//                return
//            }
            
            Utils.logFirebaseEvent(eventName: "login_google")
            self.handleSignInButton()
       // }
        
    }
    @IBAction func appleSigninButtonPressed(_ sender: Any) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
//        self.handleRecapatcha { [weak self] in
//
//            guard let `self` = self else {
//                return
//            }
            
            Utils.logFirebaseEvent(eventName: "login_apple")
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
       // }
    }
    func handleSignInButton() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error == nil else { return }
            guard let signInResult = signInResult else { return }
            
            let user = signInResult.user
            let idToken = user.idToken
            
            let accessToken = user.accessToken
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken?.tokenString ?? "", accessToken: accessToken.tokenString)
  
            let emailAddress = user.profile?.email
            
            let fullName = user.profile?.name ?? ""
            print(fullName)
            let givenName = user.profile?.givenName
            let familyName = user.profile?.familyName
            
            
            
            
            let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            let username = (givenName ?? "") + (familyName ?? "")
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
//            Utils.user = User(profile_pic: profilePicUrl?.absoluteString ?? "", username: username, email: emailAddress ?? "", phone: "", zip_code: "", fullName: fullName)
            Auth.auth().signIn(with: credential) { result, error in
                
               
                if error == nil{
                    Utils.isEmailExistInFirebase(email: emailAddress ?? "") { isExists in
                        if isExists{
                            self.count = self.count + 1
                            if self.count == 1{
                                if  Utils.checkUserSavedInSharedPrefrences(email:emailAddress ?? "") {
                                    self.navigateToHome()
                                }else{
                                    var userSavedList = Utils.getAccountsWhoInLoggedin()
                                    userSavedList.append(UserObjectSP(user_id:  result?.user.uid ?? "",
                                                                      username: user.profile?.name ?? "",
                                                                      email: emailAddress ?? "",
                                                                      userImage: profilePicUrl?.absoluteURL.absoluteString ?? "",
                                                                      normal: false,
                                                                      gmail: true,
                                                                      facebook: false,
                                                                      apple: false))
                                    Utils.saveAccountInLoggedInUser(userList: userSavedList)
                                    self.navigateToHome()
                                }
                                
                            }
                        }else{
                            self.saveFirebaseData(username: username, email: emailAddress ?? "", phone: "", zip: "", photo: profilePicUrl?.absoluteURL.absoluteString ?? "", fullName: fullName) { url in
                            }
                        }
                    }
                }else{
                    print(error?.localizedDescription ?? "")
                }
            }
            
        }
    }

    
    func saveFirebaseData(username: String, email: String, phone: String,zip: String, photo: String,fullName: String, completion: @escaping((_ url: URL?) -> ())){
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        var allusers = [User]()
        Utils.getAllUsers { users in
            allusers = users
            let user = User(profile_pic: photo, username: username, email: email, phone: phone, zip_code: zip,fullName: fullName ,uid: Auth.auth().currentUser?.uid ?? "")
            let data = try! FirebaseEncoder().encode(user)
            self.database.child("users").child(Auth.auth().currentUser?.uid ?? "").setValue(data)
        }
        
        
        let createUpdateRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        createUpdateRequest?.photoURL = URL(string: photo)
        createUpdateRequest?.displayName = username
        createUpdateRequest?.commitChanges(completion: { error in
            if error == nil{
                var userSavedList = Utils.getAccountsWhoInLoggedin()
                userSavedList.append(UserObjectSP(user_id: Auth.auth().currentUser?.uid ?? "",
                                                  username: username,
                                                  email: email,
                                                  userImage: photo,
                                                  normal: true,
                                                  gmail: false,
                                                  facebook: false,
                                                  apple: false))
                Utils.saveAccountInLoggedInUser(userList: userSavedList)
                
                self.navigateToHome()
            }else{
                print(error?.localizedDescription ?? "")
            }
        })
    }
   
    
    
    func navigateToHome(){
        MBProgressHUD.hide(for: self.view, animated: true)
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: TabBarController.self)) as! TabBarController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func navigateToSignup(){
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SignupViewController.self)) as! SignupViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func signupPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SignupViewController.self)) as! SignupViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func login(){
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        Utils.logFirebaseEvent(eventName: "login_email_password")
        self.startLoader()
        Auth.auth().signIn(withEmail: emailTF.text ?? "", password: passwordTF.text ?? "") { [weak self] authResult, error in
            guard let `self` = self else { return }
            if error == nil{
              var userid  = authResult?.user.uid ?? ""
              var emailAddress  = authResult?.user.email ?? ""
              var username  = authResult?.user.displayName ?? ""
                
                if  Utils.checkUserSavedInSharedPrefrences(email:emailAddress) {
                    self.navigateToHome()
                }else{
                    var userSavedList = Utils.getAccountsWhoInLoggedin()
                    userSavedList.append(UserObjectSP(user_id: userid,
                                                      username: username,
                                                      email: emailAddress ,
                                                      userImage: "",
                                                      normal: true,
                                                      gmail: false,
                                                      facebook: false,
                                                      apple: false))
                    Utils.saveAccountInLoggedInUser(userList: userSavedList)
                    self.navigateToHome()
                }
            }else{
                self.stopLoader()
                self.alert(title: "Error", message: "Incorrect Email or Password")
            }
        }
    }
}






//FaceBook Auth
extension LoginViewController: LoginButtonDelegate{
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: Error?) {
        if let error = error {
            print("Facebook login failed with error: \(error.localizedDescription)")
            return
        }
        
        guard let accessToken = AccessToken.current else {
            print("Unable to get access token")
            return
        }
        
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
        self.startLoader()
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print("Firebase authentication failed with error: \(error.localizedDescription)")
                return
            }
            
            let email = authResult?.user.email ?? ""
            let name = authResult?.user.displayName ?? ""
            let uid = authResult?.user.uid ?? ""
            let phone = authResult?.user.phoneNumber ?? ""
            let photo = authResult?.user.photoURL?.absoluteString ?? ""
            // User is signed in to Firebase with Apple.
            DispatchQueue.main.async {[self] in
                let databaseReff = Database.database().reference().child("users")
                databaseReff.queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.value, with: { snapshot in
                    if snapshot.exists(){
                        self.saveFirebaseData(username: name, email: email, phone: phone, zip: "", photo: photo, fullName: name) { url in
                            self.stopLoader()
                            self.navigateToHome()
                        }
                    }else{
                        self.stopLoader()
                        self.navigateToHome()
                    }
                })
            }
            
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        try! Auth.auth().signOut()
        print("User logged out")
    }
}
//Apple Auth
extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: "",
                                                           fullName: appleIDCredential.fullName)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if (error != nil) {
                    print(error?.localizedDescription ?? "")
                    return
                }
                if Utils.user?.username == "" || Utils.user?.username == nil{
                    let name = (appleIDCredential.fullName?.givenName ?? "") + "" + (appleIDCredential.fullName?.familyName ?? "")
                    self.saveFirebaseData(username: "", email: appleIDCredential.email ?? "" , phone: "", zip: "", photo: "",fullName: name) { url in
                        
                    }
                }else{
                    self.navigateToHome()
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
