//
//  AddPostViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit
import FirebaseAuth
import Photos
import BSImagePicker
import IQKeyboardManagerSwift
import MBProgressHUD
import FirebaseDatabase
import PhotosUI
import SDWebImage
import AVKit
import FirebaseStorage
import MobileCoreServices
import GoogleMaps
import GooglePlaces


protocol AddPostViewControllerDelegate{
    func postEdited(post: Post)
}

class AddPostViewController: UIViewController {
    
    @IBOutlet weak var viewToDismiss: UIView!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblTextCount: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var attachView: UIView!
    @IBOutlet weak var addNudgeButton: UIButton!
    @IBOutlet weak var lblTaggedBusiness: UILabel!
    @IBOutlet weak var taglbl: UILabel!
    @IBOutlet weak var lblHeading: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tagView: UIView!
    
    var searchtext = ""
    var taggedUsers = [TaggedUsers]()
    var searchedUsers = [User]()
    var delegate: AddPostViewControllerDelegate?
    var isFromEdit = false
    var imagesSelected = [UIImage]()
    var imageVideosToShow = [UIImage]()
    var urls: [URL] = []
    var post: Post?
    var selectedBusiness: Business? = nil
    var count = 0
    var videoURLS = [URL]()
    var stringArray = [String]()
    var feeds = [Feed]()
    var users = [User]()
    var selectedTagUser: User?
    var arrayString: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logPageView()
        
        self.tabBarController?.delegate = self
        Utils.getFeedsForCurrentUser { feeds in
            self.feeds = feeds
        }
        Utils.getAllUsers { users in
            self.users = users
            self.tableView.reloadData()
        }
        addObservers()
        setView()
        if isFromEdit{
            editPostSetView()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.viewToDismiss.addGestureRecognizer(tap)
        setTraits()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setTraits()
    }
    func setTraits(){
        self.profileImageView.borderColor = self.isDarkModeEnabled() ? UIColor.white : UIColor.clear
        self.profileImageView.borderWidth = 1.0
    }
    @objc func dismissKeyboard(){
        self.postTextView.resignFirstResponder()
    }
    
    func editPostSetView(){
        postTextView.resignFirstResponder()
        lblHeading.text = "Edit Post"
        postTextView.text = post?.post_text
        postTextView.textColor = UIColor.black
        addNudgeButton.setTitle("Edit Nudge", for: .normal)
        
        lblTextCount.text =  "\(postTextView.text.count)/300"
        if self.post?.tagged_business != nil{
            self.selectedBusiness = self.post?.tagged_business
            taglbl.isHidden = false
            lblTaggedBusiness.isHidden = false
            lblTaggedBusiness.text = self.post?.tagged_business?.name ?? ""
        }
        for i in 0..<(post?.image_urls?.count ?? 0){
            if post?.image_urls?[i].contains("videos") ?? false{
                self.videoURLS.append(URL(string: post?.image_urls?[i] ?? "")!)
                getThumnails(url: post?.image_urls?[i] ?? "") {
                    self.stopLoader()
                    self.collectionView.reloadData()
                }
            }else if post?.image_urls?[i].contains("post_images") ?? false{
                getUIimages(urlString: self.post?.image_urls?[i] ?? "") {
                    self.stopLoader()
                    self.collectionView.reloadData()
                }
            }
        }
        
        //        if post?.image_urls?.count ?? 0 > 0{
        //            for i in 0..<(post?.image_urls?.count ?? 0){
        //                if post?.image_urls?[i].contains("post_images") ?? false{
        //                    getUIimages(urlStrings: self.post?.image_urls ?? []) {
        //                        self.stopLoader()
        //                        self.collectionView.reloadData()
        //                    }
        //                }else{
        //                    getThumnails(urls: self.post?.image_urls ?? []) {
        //                        self.collectionView.reloadData()
        //                    }
        //
        //                    print("video found")
        //                }
        //            }
        //
        //        }else{
        //            attachView.isHidden = true
        //        }
    }
    
    func setView(){
        self.videoURLS = [URL]()
        self.imagesSelected = [UIImage]()
        self.imageVideosToShow = [UIImage]()
        self.collectionView.reloadData()
        lblTextCount.text = "0/300"
        taglbl.isHidden = true
        lblTaggedBusiness.isHidden = true
        self.selectedBusiness = nil
        lblHeading.text = "Add Post"
        lblName.text = "\(Auth.auth().currentUser?.displayName ?? "")"
        Utils.loadImage(imageView: profileImageView, urlString: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", placeHolder: UIImage(named: "placeholder"))
        postTextView.delegate = self
        postTextView.text = ""
        postTextView.textColor = UIColor.lightGray
        postTextView.becomeFirstResponder()
        attachView.isHidden = (imageVideosToShow.count == 0)
    }
    
    func getUIimages(urlString: String, completionHandler: @escaping () -> Void){
        self.startLoader()
        //        for urlString in urlStrings {
        if let url = URL(string: urlString) {
            SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { image, _, _, _, _, _ in
                if let image = image {
                    self.imagesSelected.append(image)
                    self.imageVideosToShow.append(image)
                    self.stringArray.append("image")
                }
                
                self.stopLoader()
                completionHandler()
            }
        }
        //        }
    }
    func getThumnails(url: String, completionHandler: @escaping () -> Void){
        self.startLoader()
        //        for url in urls {
        //            DispatchQueue.global().async {
        let asset = AVAsset(url: URL(string: url)!)
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: 1, timescale: 2)
        let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil)
        if img != nil {
            let frameImg  = UIImage(cgImage: img!)
            DispatchQueue.main.async(execute: {
                self.imageVideosToShow.append(frameImg)
                self.stringArray.append("video")
                self.collectionView.reloadData()
            })
        }
        //            }
        //        }
        self.stopLoader()
        
        completionHandler()
    }
    deinit {
        removeObservers()
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
        setView()
        if self.tabBarController?.selectedIndex != 2{
            self.navigationController?.popViewController(animated: true)
        }
        self.tabBarController?.selectedIndex = 0
    }
    
    @IBAction func didPressPostButton(_ sender: Any) {
        if isFromEdit{
            editPost()
            Utils.logFirebaseEvent(eventName: "edit_post")
        }else{
            addPost()
            Utils.logFirebaseEvent(eventName: "create_new_post")
            if Utils.user?.city != "" && Utils.user?.cityLat != 0.0 && Utils.user?.cityLng != 0.0 {
                Utils.addTown(Town(name: Utils.user?.city ?? "", noOfCheckIns: 0, lat: Utils.user?.cityLat ?? 0.0, lng: Utils.user?.cityLng ?? 0.0))
            }
            
        }
    }
    
    func addPost(){
        let posttext = postTextView.text == "What's happening?" ? "" : postTextView.text ?? ""
        self.startLoader()
        urls.removeAll()
        uploadImages { [self] in
            if urls.count == imagesSelected.count {
                if videoURLS.count > 0{
                    urls.append(contentsOf: videoURLS)
                }
                let model = Post(user_id: Auth.auth().currentUser?.uid ?? "", image_urls: self.urls.map({ url in
                    return url.absoluteString
                }), post_text: posttext,tagged_business: self.selectedBusiness, user: Utils.initiateUser(), like_count: 0,video_urls: self.videoURLS.map({ url in
                    return url.absoluteString
                }),tagged_users1: self.taggedUsers)
                if ((postTextView.text == "" || postTextView.text == "What's happening?") && imageVideosToShow.isEmpty){
                    self.alert(title: "Error", message: "Please add atleast text or one image/video")
                    self.stopLoader()
                }else{
                    self.saveDataToFirebase(child: FirebaseKeys.postTable, subChild: true, model: model) { post_id in
                        if !self.taggedUsers.isEmpty{
                            for i in 0..<self.taggedUsers.count{
                                Utils.addNotificationForTag(user_id: self.taggedUsers[i].user_id, post_id: post_id, event: .post_tag,sender_user_id: Auth.auth().currentUser?.uid ?? "")
                                if let user = Utils.getUser(user_id: self.taggedUsers[i].user_id){
                                    Utils.sendNotification(fcm: user.fcm ?? "", event: .post_tag, user: user,name: Auth.auth().currentUser?.displayName ?? "",post_id: post_id, user_id: Auth.auth().currentUser?.uid ?? "")
                                }
                            }
                        }
                    }
                    
                    fetchPlaceDetails(placeID: self.selectedBusiness?.place_id ?? "") { place in
                        print(place)
                    }
                    
                    NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                    self.stopLoader()
                    self.backPressed(self)
                }
            }
        }
    }
    func editPost(){
        guard Utils.shared.isInternetAvailable() else {
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let ref = Database.database().reference().child(FirebaseKeys.postTable).child(post?.user_id ?? "" ).child(post?.post_id ?? "")
        self.startLoader()
        uploadImages { [self] in
            if urls.count == imagesSelected.count {
                if videoURLS.count > 0{
                    urls.append(contentsOf: videoURLS)
                }
                var model = Post(user_id: Auth.auth().currentUser?.uid ?? "", image_urls: self.urls.map({ url in
                    return url.absoluteString
                }), post_text: postTextView.text ?? "",tagged_business: self.selectedBusiness, user: Utils.initiateUser(), like_count: post?.like_count ?? 0,dislike_count: post?.dislike_count ?? 0)
                model.post_dislikes = post?.post_dislikes
                model.comments = post?.comments
                model.post_likes = post?.post_likes
                model.post_id = post?.post_id ?? ""
                ref.updateChildValues(model.dictionary) { error, ref in
                    if error == nil {
                        print("updated")
                        NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
                        if self.post != nil{
                            self.post = model
                            self.delegate?.postEdited(post: self.post!)
                        }
                    }
                }
            }
            self.stopLoader()
            self.backPressed(self)
        }
    }
    
    func fetchPlaceDetails(placeID: String,onCompletion: @escaping (String) -> Void) {
        let placesClient = GMSPlacesClient.shared()
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: .all, sessionToken: nil) { (place, error) in
            if let error = error {
                print("Error fetching place details: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                // Access the desired place details
                let phoneNumber = place.phoneNumber ?? ""
                let website = place.website?.absoluteString ?? ""
                
                print("Phone number: \(phoneNumber)")
                print("Website: \(website)")
                let model = CheckIn(place_id: placeID,place_photo: nil, is_hottest: false, place_name: place.name, place_address: place.formattedAddress, open_now: place.isOpen().rawValue == 1 ? true : false, close_time: "", phone: phoneNumber, email: website, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude, posts: nil, reviews: nil,tagged_points: self.selectedBusiness != nil ? 1 : nil)
                self.isPlaceExists(placeID: placeID) { value in
                    if !value{
                        print("added")
                        Database.database().reference().child("checkins").child(placeID).updateChildValues(model.dictionary) { error, ref in
                            if error == nil{
                                onCompletion(placeID)
                            }
                        }
                        
                    }else{
                        self.getTaggedPointsForAlreadyAddedCheckin(place_id: place.placeID ?? "", onCmpletion: { getValue in
                            Database.database().reference().child("checkins").child(place.placeID ?? "").updateChildValues(["tagged_points":getValue == 0 ? 1 : getValue + 1])
                        })
                        Database.database().reference().child("checkins").child(place.placeID ?? "").updateChildValues(["open_now": place.isOpen().rawValue == 1 ? true : false])
                        onCompletion(placeID)
                        print("added already")
                    }
                }
            }
        }
    }
    func isPlaceExists(placeID: String, onCompletion: @escaping (Bool) -> Void) {
        Database.database().reference().child("checkins").child(placeID).observeSingleEvent(of: .value) { snapshot in
            onCompletion(snapshot.exists())
        }
    }
    func getTaggedPointsForAlreadyAddedCheckin(place_id: String, onCmpletion: @escaping (Int) -> Void){
        Database.database().reference().child("checkins").child(place_id).child("tagged_points").observeSingleEvent(of: .value) { snapshot in
            onCmpletion(snapshot.value as? Int ?? 0)
            print(snapshot)
        }
    }
    
    func uploadImages(index: Int = 0, completionHandler: @escaping () -> Void){
        if index >= imagesSelected.count {
            completionHandler()
            return
        }
        uploadImage(child: FirebaseKeys.postImages, _image: imagesSelected[index]) { [self] url in
            guard let url = url else {
                uploadImages(index: index + 1) {
                    completionHandler()
                }
                return
            }
            
            urls.append(url)
            uploadImages(index: index + 1) {
                completionHandler()
            }
        }
    }
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        PhotoPicker.shared.delegate = self
        PhotoPicker.shared.capturePhoto(with: self)
        Utils.logFirebaseEvent(eventName: "create_post_camera_view")
    }
    @IBAction func galleryButtonPressed(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 10 // 0 means no limit
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
        Utils.logFirebaseEvent(eventName: "create_post_gallery_view")
    }
    @IBAction func tagUserButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Post", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: TagBusinessViewController.self)) as! TagBusinessViewController
        vc.delegate = self
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true)
        Utils.logFirebaseEvent(eventName: "create_post_tag_view")
    }
}

extension AddPostViewController: UITextViewDelegate{
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            view.endEditing(true)
            return false
        } else {
            let newLength = postTextView.text.utf16.count + text.utf16.count - range.length
            lblTextCount.text = "\(String(newLength))/300"
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            let numberOfChars = newText.count
            return numberOfChars < 301
        }
    }
    func filterData(for searchText: String) {
        searchedUsers = users.filter { item in
            let username = item.username ?? ""
            return username.lowercased().contains(searchText)
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else { return }
        if text.hasSuffix("@") {
            tagView.isHidden = false
            tableView.reloadData()
        } else if text.contains("@") {
            let searchTerm = extractSearchTerm(from: text)
            filterNames(with: searchTerm)
        } else {
            tagView.isHidden = true
        }
    }
    func filterNames(with searchTerm: String) {
        searchedUsers = users.filter({
            let username = $0.username ?? ""
            return username.lowercased().contains(searchTerm.lowercased())
        })
        tableView.reloadData()
    }
    
    func insertSelectedName(_ name: String) {
        guard var text = postTextView.text else { return }
        
        if let range = text.range(of: "@\(extractSearchTerm(from: text))") {
            text.replaceSubrange(range, with: name + " ")
        }
        
        postTextView.text = text
    }
    private func extractSearchTerm(from text: String) -> String {
        guard let lastWord = text.components(separatedBy: CharacterSet.whitespaces).last else {
            return ""
        }
        
        let searchTerm = String(lastWord.dropFirst())
        return searchTerm
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray && textView.text == "What's happening?" {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "What's happening?"
            textView.textColor = UIColor.lightGray
        }
    }
}

extension AddPostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = imageVideosToShow.count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoCollectionViewCell.self), for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
        cell.crossbtn.tag = indexPath.item
        cell.postid = post?.post_id ?? ""
        cell.delegate = self
        if imageVideosToShow.count > 0{
            cell.photoImageView.image = imageVideosToShow[indexPath.item]
        }else{
            cell.photoImageView.image = UIImage(named: "placeholderImage")
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 86, height: 86)
    }
}

extension AddPostViewController: PhotoPickerDelegate{
    func didFinish(image: UIImage) {
        self.imagesSelected.append(image)
        self.imageVideosToShow.append(image)
        self.stringArray.append("image")
        self.collectionView.reloadData()
    }
}

extension AddPostViewController: TagBusinessViewControllerDelegate{
    func businessSelected(business: Business){
        lblTaggedBusiness.isHidden = false
        taglbl.isHidden = false
        lblTaggedBusiness.text = business.name
        self.selectedBusiness = business
    }
}
extension AddPostViewController: PhotoCollectionViewCellDelegate{
    func deleteImage(index: Int,postid: String) {
        if isFromEdit{
            self.post?.image_urls?.remove(at: index)
            
        }
        //        }else{
        if stringArray[index] == "video"{
            if imagesSelected.count == 0{
                self.videoURLS.remove(at: index)
            }else{
                if index - imagesSelected.count < 0{
                    self.videoURLS.remove(at: index - self.imagesSelected.count + 1)
                }else{
                    self.videoURLS.remove(at: index - self.imagesSelected.count)
                }
            }
        }else{
            self.imagesSelected.remove(at: index)
        }
        self.stringArray.remove(at: index)
        self.imageVideosToShow.remove(at: index)
        attachView.isHidden = stringArray.count == 0 ? true : false
        print("\(self.imageVideosToShow.count) images/videos left")
        //        }
        self.collectionView.reloadData()
    }
}

extension AddPostViewController: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                    }
                    if let image = image as? UIImage {
                        self.imagesSelected.append(image)
                        self.imageVideosToShow.append(image)
                        self.stringArray.append("image")
                    }
                }
            }
            else {
                // The item provider can load a URL
                if result.itemProvider.hasItemConformingToTypeIdentifier("public.movie") {
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { (url, error) in
                        if let error = error {
                            print("Error loading video data: \(error.localizedDescription)")
                        } else {
                            guard let url = url else { return }
                            do {
                                DispatchQueue.main.async {
                                    self.startLoader()
                                }
                                
                                let data = try Data(contentsOf: url)
                                print(data)
                                let uuid = UUID().uuidString
                                let storageRef = Storage.storage().reference().child("videos").child(Auth.auth().currentUser?.uid ?? "").child("\(uuid).mov")
                                // Data in memory
                                let metadata = StorageMetadata()
                                metadata.contentType = "video/quicktime"
                                let _ = storageRef.putData(data, metadata: metadata) { (metadata, error) in
                                    guard let _ = metadata else {
                                        return
                                    }
                                    storageRef.downloadURL { (url, error) in
                                        guard let downloadURL = url else {
                                            return
                                        }
                                        print(downloadURL)
                                        self.videoURLS.append(downloadURL)
                                        let asset = AVAsset(url: downloadURL)
                                        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                                        assetImgGenerate.appliesPreferredTrackTransform = true
                                        let time = CMTimeMake(value: 1, timescale: 2)
                                        let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                                        if img != nil {
                                            let frameImg  = UIImage(cgImage: img!)
                                            self.imageVideosToShow.append(frameImg)
                                            //                                            self.imagesSelected.append(frameImg)
                                            self.stringArray.append("video")
                                        }
                                        DispatchQueue.main.async {
                                            self.stopLoader()
                                            self.collectionView.reloadData()
                                        }
                                        
                                    }
                                }
                            } catch {
                                print("Error loading video data: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
        self.startLoader()
        picker.dismiss(animated: true) {[weak self] in
            guard let `self` = self else { return }
            print("\(self.imagesSelected.count) images added")
            print("didFinishPicking")
            self.attachView.isHidden = (self.imageVideosToShow.count == 0)
            self.postTextView.resignFirstResponder()
            self.stopLoader()
            self.collectionView.reloadData()
        }
    }
}
extension AddPostViewController: UITabBarControllerDelegate{
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("selected index = \(tabBarController.selectedIndex)")
        if tabBarController.selectedIndex == 2{
            setView()
            self.tabBarController?.tabBar.isHidden = true
        }else{
            self.tabBarController?.tabBar.isHidden = false
        }
    }
}
extension AddPostViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagUserTableViewCell") as! TagUserTableViewCell
        cell.lblName.text = (searchedUsers[indexPath.row].fullName == "" ? searchedUsers[indexPath.row].username : searchedUsers[indexPath.row].fullName)
        Utils.loadImage(imageView: cell.imgView, urlString: searchedUsers[indexPath.row].profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.taggedUsers.append(TaggedUsers(user_id: searchedUsers[indexPath.row].uid ?? ""))
        let selectedName = searchedUsers[indexPath.row].username ?? ""
        insertSelectedName(selectedName)
        tagView.isHidden = true
    }
}
