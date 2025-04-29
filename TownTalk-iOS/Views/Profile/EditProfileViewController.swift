//
//  EditProfileViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase

class EditProfileViewController: BaseViewController, UITextViewDelegate {
    
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var zipcodeTF: UITextField!
    @IBOutlet weak var fullNameTF: UITextField!
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var bioTV: UITextView!
    @IBOutlet weak var lblTextCount: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var selectedlat = 0.0
    var selectedLng = 0.0
    var selectedCity = ""
    var isPickedImage: Bool = false
    var photoURL = URL(string: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bioTV.delegate = self
        bioTV.text = "Add Bio.."
        setupView()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
                
                // Add a tap gesture recognizer to dismiss the keyboard
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                scrollView.addGestureRecognizer(tapGesture)
    }
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            // Unregister from keyboard notifications
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func keyboardWillShow(_ notification: Notification) {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
                scrollView.contentInset = contentInset
                scrollView.scrollIndicatorInsets = contentInset
            }
        }
        
        @objc func keyboardWillHide(_ notification: Notification) {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
        }
        
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.labelColor
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add Bio.."
            textView.textColor = UIColor.lightGray
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let newLength = bioTV.text.utf16.count + text.utf16.count - range.length
        lblTextCount.text =  "\(String(newLength))/100"
        let numberOfChars = newText.count
        return numberOfChars < 100
    }
    
    func setupView(){
        Utils.loadImage(imageView: profileImgView, urlString: Utils.user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
        usernameTF.text = "\(Utils.user?.username ?? "")"
        fullNameTF.text = Utils.user?.fullName ?? ""
        emailTF.text = Utils.user?.email ?? (Auth.auth().currentUser?.email ?? "")
        bioTV.text = Utils.user?.bio == "" ? "Add Bio.." : Utils.user?.bio
        bioTV.textColor = Utils.user?.bio ?? "" == "" ? UIColor.lightGray : UIColor.labelColor
        lblTextCount.text = Utils.user?.bio ?? "" == "" ? "0/100" : "\(bioTV.text.count)/100"
        zipcodeTF.text = Utils.user?.city ?? ""
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func selectCity(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Location", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SelectLocationViewController.self)) as! SelectLocationViewController
        vc.delegate = self
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true)
    }
    
    @IBAction func editImageButtonPressed(_ sender: Any) {
        PhotoPicker.shared.delegate = self
        PhotoPicker.shared.pickPhoto(with: self)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if isPickedImage{
            editProfileWithImage()
            
            Utils.logFirebaseEvent(eventName: "update_personal_profile_image")
        }else{
            editProfileWithoutImage()
            Utils.logFirebaseEvent(eventName: "update_personal_profile")
        }
    }
    func editProfileWithImage(){
        self.startLoader()
        self.uploadImage(child: FirebaseKeys.profilePhtosStorage, _image: profileImgView.image ?? UIImage()) {[self] url in
            let user = User(profile_pic: url?.absoluteString ?? "", username: usernameTF.text ?? "", email: emailTF.text ?? "", phone: Auth.auth().currentUser?.phoneNumber ?? "", zip_code: zipcodeTF.text ?? "", fullName: fullNameTF.text ?? "",bio: bioTV.text == "Add Bio.." ? nil : bioTV.text ?? "",city: zipcodeTF.text ?? "")
            self.photoURL = url
            guard Utils.shared.isInternetAvailable() else {
                self.alert(title: "Error", message: "No Internet Available")
                return
            }
            let ref = Database.database().reference().child(FirebaseKeys.userTable).child(Auth.auth().currentUser?.uid ?? "")
            ref.updateChildValues(user.dictionary) { error, ref in
                if error == nil {
                    let createUpdateRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    createUpdateRequest?.photoURL = self.photoURL
                    createUpdateRequest?.displayName = self.fullNameTF.text ?? ""
                    
                    createUpdateRequest?.commitChanges(completion: { error in
                        if error == nil{
                            Utils.user = user
                            Constants.postLocation = PostLocation(city_name: self.selectedCity, state_name: "", latitude: self.selectedlat, longitude: self.selectedLng)
                            Utils.fetchCurrentUser()
                            Constants.currentLocation = self.zipcodeTF.text ?? ""
                            self.stopLoader()
                            self.isPickedImage = false
                            self.navigationController?.popViewController(animated: true)
                        }else{
                            print(error?.localizedDescription ?? "")
                        }
                    })
                }
            }
        }
    }
    func editProfileWithoutImage(){
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        self.startLoader()
        let user = User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: usernameTF.text ?? "", email: emailTF.text ?? "", phone: Auth.auth().currentUser?.phoneNumber ?? "", zip_code: zipcodeTF.text ?? "", fullName: fullNameTF.text ?? "",bio: bioTV.text == "Add Bio.." ? nil : bioTV.text ?? "",city: zipcodeTF.text ?? "",cityLat: Constants.currentLatitude,cityLng: Constants.currentLongitude)
        let ref = Database.database().reference().child(FirebaseKeys.userTable).child(Auth.auth().currentUser?.uid ?? "")
        ref.updateChildValues(user.dictionary) { error, ref in
            if error == nil {
                let createUpdateRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                createUpdateRequest?.displayName = self.fullNameTF.text ?? ""
                createUpdateRequest?.commitChanges(completion: { error in
                    if error == nil{
                        Constants.postLocation = PostLocation(city_name: self.selectedCity, state_name: "", latitude: self.selectedlat, longitude: self.selectedLng)
                        Utils.user = user
                        Constants.currentLocation = self.zipcodeTF.text ?? ""
                        Utils.fetchCurrentUser()
                        self.stopLoader()
                        self.navigationController?.popViewController(animated: true)
                    }else{
                        print(error?.localizedDescription ?? "")
                    }
                })
            }
        }
    }
    func updateUserUnderPost(){
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        Database.database().reference().child(FirebaseKeys.postTable).observeSingleEvent(of: .value, with: { snapshot in
            var userid = ""
            var postid = ""
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    userid = key
                    let posts = value as? Dictionary<String, Any>
                    posts?.forEach({ (key: String, value: Any) in
                        postid = key
                    })
                }
            }
            guard Utils.shared.isInternetAvailable() else {
                self.alert(title: "Error", message: "No Internet Available")
                return
            }
            let ref = Database.database().reference().child(FirebaseKeys.postTable).child(userid).child(postid).child("user")
            ref.updateChildValues(Utils.user?.dictionary ?? [:]) { error, ref in
                if error == nil {
                    print("updated post user also")
                }else{
                    print("there was some error")
                }
            }
        })
    }
}

extension EditProfileViewController: PhotoPickerDelegate{
    func didFinish(image: UIImage) {
        isPickedImage = true
        profileImgView.image = image
    }
}
extension EditProfileViewController: SelectLocationViewControllerDelegate{
    func selectCity(city: String,lat: Double, lng: Double) {
        self.selectedlat = lat
        self.selectedLng = lng
        self.zipcodeTF.text = city
        Constants.currentLatitude = lat
        Constants.currentLongitude = lng
        self.selectedCity = city
    }
}
