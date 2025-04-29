//
//  BaseViewController.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase
import FirebaseStorage
import MBProgressHUD
import AVKit
import AVFoundation
import FirebaseAnalytics

extension BaseViewController: UITabBarControllerDelegate{
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("selecte")
        if tabBarController.selectedIndex == 2{
            self.tabBarController?.tabBar.isHidden = true
        }else{
            self.tabBarController?.tabBar.isHidden = false
        }
    }
}

extension UIViewController {
    
    public func logPageView(file: String = #file) {
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            "event_name": String(describing: self.classForCoder)
        ])
        
        print("==============================")
        print("Logged page: \(String(describing: self.classForCoder))")
        print("==============================")
    }
}

class BaseViewController: UIViewController,UINavigationControllerDelegate {
    
    //    var user: User!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupToHideKeyboardOnTapOnView()
        self.tabBarController?.delegate = self
        
        self.logPageView()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func CollectionviewNoDataAvailabl(collection_view : UICollectionView , text : String , color:UIColor = UIColor.darkGray ) {
        let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: collection_view.bounds.size.width, height: collection_view.bounds.size.height))
        noDataLabel.font = UIFont.satoshiRegular(withSize: 15)
        noDataLabel.text          = text + "   "
        noDataLabel.textColor     = color
        noDataLabel.textAlignment = .center
        collection_view.backgroundView  = noDataLabel
    }
    
    func TableViewRemoveNoDataLable(tableview : UITableView ) {
        tableview.backgroundView  = nil
    }
    
    func CollectionViewRemoveNoDataLable(collection_view : UICollectionView ) {
        collection_view.backgroundView  = nil
    }
    func TableViewNoDataAvailabl(tableview : UITableView , text : String, textColor: UIColor = UIColor.darkGray) {
        
        let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableview.bounds.size.width, height: tableview.bounds.size.height))
        noDataLabel.font = UIFont.satoshiRegular(withSize: (UIDevice.current.userInterfaceIdiom == .pad) ? 26 : 15)
        noDataLabel.text          = text + "   "
        noDataLabel.textColor     = self.isDarkModeEnabled() ? UIColor.white : UIColor.black
        noDataLabel.textAlignment = .center
        tableview.backgroundView  = noDataLabel
        tableview.separatorStyle  = .none
    }
    
    func showCustomAlert(title:String, message:String, btnString: String, handlers: ((UIAlertAction) -> Void)? = nil){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: btnString, style: .cancel, handler: handlers))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func popViewController(){
        self.navigationController?.popViewController(animated: true)
    }
    func estimatedHeightOfLabel(text: String) -> CGFloat {
        
        let size = CGSize(width: view.frame.width - 16, height: 1000)
        
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        let attributes = [NSAttributedString.Key.font: UIFont.satoshiRegular(withSize: 16)]
        
        let rectangleHeight = String(text).boundingRect(with: size, options: options, attributes: attributes as [NSAttributedString.Key : Any], context: nil).height
        
        return rectangleHeight
    }
    func setupToHideKeyboardOnTapOnView(){
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
    func currentUser(completionHandler: @escaping (User) -> Void){
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").observe(.value) { snapshot in
            if snapshot.value != nil {
                let user = try! FirebaseDecoder().decode(User.self, from: snapshot.value!)
                completionHandler(user)
            }
        }
    }
    
    func uploadImage(child: String,_image: UIImage,completion: @escaping (_ url: URL?) -> ()){
        let uuid = UUID().uuidString
        let storageRef = Storage.storage().reference().child(child).child(Auth.auth().currentUser?.uid ?? "").child("\(_image.accessibilityIdentifier ?? "")\(uuid)")
        let imageData = _image.jpegData(compressionQuality: 1.0)
        let metaData = StorageMetadata()
        metaData.contentType = "image/png"
        storageRef.putData(imageData!, metadata: metaData){ (metaData,error) in
            if error == nil{
                print("success")
                storageRef.downloadURL { url, error in
                    completion(url)
                }
            }else{
                completion(nil)
            }
        }
    }
    
    func saveDataToFirebase<T : Codable>(child: String, subChild: Bool = false, model: T,completion: @escaping (String) -> (Void)){
        let data = try! FirebaseEncoder().encode(model)
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        if(subChild) {
            Database.database().reference().child(child).child(Auth.auth().currentUser?.uid ?? "").childByAutoId().setValue(data)
        }else {
            Database.database().reference().child(child).child(Auth.auth().currentUser?.uid ?? "").setValue(data)
        }
    }
    func stopLoader(){
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    func startLoader(){
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        
        let vc = AVPlayerViewController()
        vc.player = player
        
        self.present(vc, animated: true) { vc.player?.play() }
    }
    
    
    
    func fetchAllUsers(){
        Database.database().reference().child("users").observe(.value) { snapshot in
            Constants.users.removeAll()
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    var user = try! FirebaseDecoder().decode(User.self, from: value)
                    user.uid = key
                    Constants.users.append(user)
                }
            }
        }
    }
}

extension AddPostViewController{
    func stopLoader(){
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    func startLoader(){
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    func uploadImage(child: String,_image: UIImage,completion: @escaping (_ url: URL?) -> ()){
        let uuid = UUID().uuidString
        let storageRef = Storage.storage().reference().child(child).child(Auth.auth().currentUser?.uid ?? "").child("\(_image.accessibilityIdentifier ?? "")\(uuid)")
        let imageData = _image.jpegData(compressionQuality: 1.0)
        let metaData = StorageMetadata()
        metaData.contentType = "image/png"
        storageRef.putData(imageData!, metadata: metaData){ (metaData,error) in
            if error == nil{
                print("success")
                storageRef.downloadURL { url, error in
                    completion(url)
                }
            }else{
                completion(nil)
            }
        }
    }
    
    func saveDataToFirebase<T : Codable>(child: String, subChild: Bool = false, model: T,completion: @escaping (String) -> (Void)){
        let data = try! FirebaseEncoder().encode(model)
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        if(subChild) {
            Database.database().reference().child(child).child(Auth.auth().currentUser?.uid ?? "").childByAutoId().setValue(data) { error, ref in
                if error == nil{
                    completion(ref.key ?? "")
                }
            }
        }else {
            Database.database().reference().child(child).child(Auth.auth().currentUser?.uid ?? "").setValue(data)
        }
    }
}
extension UIViewController{
    func isDarkModeEnabled() -> Bool {
        if UserDefaults.standard.bool(forKey: "darkmode") == true{
            return true
        }else{
            return false
        }
    }
}
extension UICollectionViewCell{
    func isDarkModeEnabled() -> Bool {
        if UserDefaults.standard.bool(forKey: "darkmode") == true{
            return true
        }else{
            return false
        }
    }
}

extension UITableViewCell{
    func isDarkModeEnabled() -> Bool {
        if UserDefaults.standard.bool(forKey: "darkmode") == true{
            return true
        }else{
            return false
        }
    }
}
