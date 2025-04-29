//
//  SignupViewController.swift
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

class SignupViewController: BaseViewController {
    
    @IBOutlet weak var uploadImageView: UIImageView!
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var phoneTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPassTF: UITextField!
    
    let recaptcha = try? ReCaptcha(
        apiKey: "6LctwYYnAAAAAHJ_qF-RbZQ1xvNoHJnXpDOfvG0c",
        baseURL: URL(string: "http://townTalkapp.app")!,
        endpoint: .alternate
    )
    
    var selectedImage: UIImage? = nil
    var count = 0
    var emailAddress = ""
    let facebookLoginButton = FBLoginButton(frame: .zero)
    var otp = ""
    private let database = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        
        recaptcha?.configureWebView { [weak self] webview in
            webview.frame = self?.view.bounds ?? CGRect.zero
        }
        
        
        if let recaptcha = recaptcha {
            //recaptcha.forceVisibleChallenge = true
        } else {
            // Handle the case where recaptcha is nil
        }
        
        
       // recaptcha?.forceVisibleChallenge = true
    }
    
    func setView(){
        usernameTF.delegate = self
        uploadImageView.cornerRadius = uploadImageView.frame.height/2
        facebookLoginButton.delegate = self
        facebookLoginButton.isHidden = true
        facebookLoginButton.permissions = ["email","public_profile"]
    }
    @IBAction func profilePicButtonPressed(_ sender: Any) {
        PhotoPicker.shared.delegate = self
        PhotoPicker.shared.pickPhoto(with: self)
    }
    @IBAction func continuePressed(_ sender: Any) {
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
                }
        if usernameTF.text == ""{
            self.alert(title: "Error", message: "Username is Empty")
        }else if emailTF.text == ""{
            self.alert(title: "Error", message: "Email is Empty")
        }else if phoneTF.text == ""{
            self.alert(title: "Error", message: "Phone is Empty")
        }else if passwordTF.text == ""{
            self.alert(title: "Error", message: "Password is Empty")
        }else if confirmPassTF.text == ""{
            self.alert(title: "Error", message: "Confirm Password is Empty")
        }else if !(Utils.shared.isValidEmail(emailTF.text ?? "")){
            self.alert(title: "Error", message: "Email is Invalid")
        }else if passwordTF.text != confirmPassTF.text{
            self.alert(title: "Error", message: "Passwords do not match")
        }else if self.selectedImage == nil{
            self.alert(title: "Error", message: "Profile Picture Missing")
        }else{
            
//            handleRecapatcha { [weak self] in
//
//                guard let `self` = self else {
//                    return
//                }
                
                self.sendEmail()
            //}
        }
    }
    func generateOTP() -> String {
        let otpDigits = 6
        var otp = ""
        for _ in 0..<otpDigits {
            let digit = Int.random(in: 0...9)
            otp += "\(digit)"
        }
        self.otp = otp
        return otp
    }
    func navigateToOTP(){
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: OTPViewController.self)) as! OTPViewController
        vc.otpCode = otp
        vc.email = emailTF.text ?? ""
        vc.username = usernameTF.text ?? ""
        vc.password = passwordTF.text ?? ""
        vc.phone = phoneTF.text ?? ""
        vc.image = self.uploadImageView.image
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func sendEmail() {
        self.startLoader()
        let apiUrl = URL(string: "https://us-central1-town-talk-9f25a.cloudfunctions.net/sendEmail")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let emailData = [
            "recipient": emailTF.text ?? "",
            "subject": "Town Talk User",
            "body": "Your OTP to register in Town Talk is \(generateOTP())"
        ]
        
        Utils.logFirebaseEvent(eventName: "send_register_otp")
        let jsonData = try? JSONSerialization.data(withJSONObject: emailData)
        request.httpBody = jsonData
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode == 200 {
                    DispatchQueue.main.async {
                        self.stopLoader()
                        self.navigateToOTP()
                    }
                    print("Email sent successfully!")
                } else {
                    DispatchQueue.main.async {
                        self.stopLoader()
                        self.alert(title: "Error", message: "Email sending failed with status code: \(statusCode)")
                    }
                    
                    print("Email sending failed with status code: \(statusCode)")
                }
            }
        }
        
        task.resume()
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
    
    @IBAction func facebookButtonPressed(_ sender: Any) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        
//        handleRecapatcha { [weak self] in
//
//            guard let `self` = self else {
//                return
//            }
            
            self.facebookLoginButton.sendActions(for: .touchUpInside)
            
       // }
    }
    @IBAction func googleButtonPressed(_ sender: Any) {
        
//        handleRecapatcha { [weak self] in
//
//            guard let `self` = self else {
//                return
//            }
            
            self.handleSignInButton()
       // }
        
    }
    @IBAction func appleButtonPressed(_ sender: Any) {
        
    }
    func handleSignInButton() {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        Utils.logFirebaseEvent(eventName: "login_google")
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error == nil else { return }
            guard let signInResult = signInResult else { return }
            
            let user = signInResult.user
            let idToken = user.idToken
            
            let accessToken = user.accessToken
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken?.tokenString ?? "", accessToken: accessToken.tokenString)
            
            let emailAddress = user.profile?.email
            
            let fullName = user.profile?.name
            print(fullName ?? "")
            let givenName = user.profile?.givenName
            let familyName = user.profile?.familyName
            
            let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            let username = (givenName ?? "") + (familyName ?? "")
            
            Auth.auth().signIn(with: credential) { result, error in
                if error == nil{
                    print(result ?? "")
                    let databaseReff = Database.database().reference().child("users")
                    databaseReff.queryOrdered(byChild: "email").queryEqual(toValue: "test@yahoo.com").observe(.value, with: { snapshot in
                        if snapshot.exists(){
                            self.alert(title: "Duplicate", message: "User Already Exist, Please Sign in to continue")
                        }else{
                            self.saveFirebaseData1(username: username, email: emailAddress ?? "", phone: "", zip: "", photo: profilePicUrl?.absoluteURL.absoluteString ?? "") { url in
                            }
                        }
                    })
                    
                }else{
                    print(error?.localizedDescription ?? "")
                }
            }
        }
    }
    func saveFirebaseData1(username: String, email: String, phone: String,zip: String, photo: String, completion: @escaping((_ url: URL?) -> ())){
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        var allusers = [User]()
        Utils.getAllUsers { users in
            allusers = users
            let user = User(profile_pic: photo, username: username, email: email, phone: phone, zip_code: zip)
            let data = try! FirebaseEncoder().encode(user)
            self.database.child("users").child(Auth.auth().currentUser?.uid ?? "").setValue(data)
        }
        
        
        let createUpdateRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        createUpdateRequest?.photoURL = URL(string: photo)
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
    
    @IBAction func signInPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension SignupViewController: PhotoPickerDelegate{
    func didFinish(image: UIImage) {
        self.selectedImage = image
        uploadImageView.image = image
    }
}
extension SignupViewController: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
        let allowedCharacterSet = CharacterSet(charactersIn: allowedCharacters)
        let typedCharacterSet = CharacterSet(charactersIn: string)
        return allowedCharacterSet.isSuperset(of: typedCharacterSet)
    }
}
extension SignupViewController: LoginButtonDelegate{
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: Error?) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
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
        Utils.logFirebaseEvent(eventName: "login_facebook")
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
                        self.saveFirebaseData(username: name, email: email, phone: phone, zip: "", photo: URL(string: photo)!) { url in
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
