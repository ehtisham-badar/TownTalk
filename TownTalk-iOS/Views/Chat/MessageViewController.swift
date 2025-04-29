//
//  MessageViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 13/05/2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase
import FirebaseStorage
import MobileCoreServices
import MBProgressHUD
import AVFoundation
import CoreLocation
import MapKit
import AVKit
import AVFoundation

class MessageViewController: UIViewController,UITextViewDelegate {
    
    @IBOutlet weak var requestView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTF: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var heightConstraintTextView: NSLayoutConstraint!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var camerButton: UIButton!
    
    var isFromShare: Bool = false
    var messages = [Message]()
    var othermessages = [Message]()
    var user: User?
    var chat: Chat?
    var editMessageIndex = -1
    var post: Post!
    let count = 20
    let reactionHeight: CGFloat = 40.0
    let spaceReactionHeight: CGFloat = 10.0
    let menuHeight: CGFloat = 200
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logPageView()
        tableView.delegate = self
        tableView.dataSource = self
        requestView.isHidden = (chat?.is_request_accepted ?? true)
        containerView.isHidden = !requestView.isHidden
        setView()
        addObservers()
        setupTextView()
        if chat?.group_id ?? "" == ""{
            fetchChat()
            otherChats()
            if user?.fullName == "" || user?.fullName == nil || user?.fullName == " "{
                lblName.text = user?.username ?? ""
            }else{
                lblName.text = user?.fullName ?? ""
            }
            Utils.loadImage(imageView: userImage, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
        }else{
            lblName.text = chat?.group_name ?? ""
            Utils.loadImage(imageView: userImage, urlString: chat?.group_image ?? "", placeHolder: UIImage(named: "placeholder"))
            messages = chat!.messages ?? [Message]()
            DispatchQueue.main.async {
                if self.messages.count > 1{
                    self.tableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: false)
                }
                
            }
            self.tableView.reloadData()
        }
        if isFromShare{
            sendPostMessage()
        }
    }
    
    func sendLocation(location: CurrentLocation){
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let data = Message(message: "", sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: self.user,location: location)
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["last_message" : "Location"])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["last_message" : "Location"])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["time" : Utils.getCurrentDateTime()])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["user" : user!.dictionary])
        
        //request
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["is_request_accepted" : true])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["is_request_accepted" : chat?.is_request_accepted ?? false])
        
        let sendUser = User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Auth.auth().currentUser?.displayName ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: "")
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["user" : sendUser.dictionary])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").childByAutoId().setValue(data.dictionary)
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).childByAutoId().setValue(data.dictionary)
        let fcm = Utils.getUser(user_id: user?.uid ?? "")?.fcm ?? ""
        Utils.sendNotification(fcm: fcm, event: .message, user: user!, name: Auth.auth().currentUser?.displayName ?? "", user_id: Auth.auth().currentUser?.uid ?? "")
        galleryButton.isHidden = false
        locationButton.isHidden = false
        sendMessageButton.isHidden = true
        messageTF.resignFirstResponder()
        messageTF.text = "Message..."
        messageTF.textColor = UIColor.lightGray
        heightConstraintTextView.constant = 105
    }
    func sendGroupLocation(){
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let data = Message(message: "", sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: self.user,location: CurrentLocation(latitude: Constants.currentLatitude, longitude: Constants.currentLongitude))
        messages.append(data)
        
        Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["last_message" : "Location"])
        Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
        Database.database().reference().child("chats").child(chat?.group_id ?? "").child("messages").setValue(messages.map({ message in
            message.dictionary
        })) { error, ref in
            if error == nil{
                self.chat?.messages?.append(data)
                self.tableView.reloadData()
            }
        }
        for i in 0..<(self.chat?.group_users?.count ?? 0){
            let fcm = Utils.getUser(user_id: self.chat?.group_users?[i].uid ?? "")?.fcm ?? ""
            Utils.sendNotification(fcm: fcm, event: .message, user: self.chat!.group_users![i], name: Auth.auth().currentUser?.displayName ?? "", user_id: Auth.auth().currentUser?.uid ?? "")
        }
        galleryButton.isHidden = false
        locationButton.isHidden = false
        sendMessageButton.isHidden = true
        messageTF.resignFirstResponder()
        messageTF.text = "Message..."
        messageTF.textColor = UIColor.lightGray
        heightConstraintTextView.constant = 105
    }

    func isChatExists(onCompletion: (Bool) -> Void){
        
    }
    func sendPostMessage(){
        let postLink = "towntalk.com://\(post.post_id)/\(post.user_id)"
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let data = Message(message: postLink, sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: self.user)
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["last_message" : postLink])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["last_message" : postLink])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["time" : Utils.getCurrentDateTime()])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["user" : user!.dictionary])
        
        //message request
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["is_request_accepted" : true])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["is_request_accepted" : chat?.is_request_accepted ?? false])
        
        
        let sendUser = User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Auth.auth().currentUser?.displayName ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: "")
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["user" : sendUser.dictionary])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").childByAutoId().setValue(data.dictionary)
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).childByAutoId().setValue(data.dictionary)
        self.getShareCount { [self] value in
            Database.database().reference().child("posts").child(post.user_id).child(post.post_id).updateChildValues(["share_count": value + 1])
            NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
        }
        
        galleryButton.isHidden = false
        locationButton.isHidden = false
        sendMessageButton.isHidden = true
        messageTF.resignFirstResponder()
        messageTF.text = "Message..."
        messageTF.textColor = UIColor.lightGray
        heightConstraintTextView.constant = 105
    }
    
    func getShareCount(onCompletion: @escaping (Int) -> Void){
        Database.database().reference().child("posts").child(post.user_id).child(post.post_id).child("share_count").observeSingleEvent(of: .value) { snapshot in
            onCompletion(snapshot.value as? Int ?? 0)
        }
    }
    
    func sendMessage(){
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let data = Message(message: messageTF.text ?? "", sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: self.user)
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["last_message" : messageTF.text!])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["last_message" : messageTF.text!])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["time" : Utils.getCurrentDateTime()])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["user" : user!.dictionary])
        
        //message request
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["is_request_accepted" : true])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["is_request_accepted" : chat?.is_request_accepted ?? false])
        
        
        let sendUser = User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Auth.auth().currentUser?.displayName ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: "")
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["user" : sendUser.dictionary])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").childByAutoId().setValue(data.dictionary)
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).childByAutoId().setValue(data.dictionary)
        let fcm = Utils.getUser(user_id: user?.uid ?? "")?.fcm ?? ""
        Utils.sendNotification(fcm: fcm, event: .message, user: user!, name: Auth.auth().currentUser?.displayName ?? "", user_id: Auth.auth().currentUser?.uid ?? "")
        galleryButton.isHidden = false
        locationButton.isHidden = false
        sendMessageButton.isHidden = true
        messageTF.resignFirstResponder()
        messageTF.text = "Message..."
        messageTF.textColor = UIColor.lightGray
        heightConstraintTextView.constant = 105
    }
    func sendGroupMessage(){
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        let data = Message(message: messageTF.text ?? "", sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: nil)
        
        messages.append(data)
        
        Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["last_message" : messageTF.text!])
        Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
        Database.database().reference().child("chats").child(chat?.group_id ?? "").child("messages").setValue(messages.map({ message in
            message.dictionary
        })) { error, ref in
            if error == nil{
                self.chat?.messages?.append(data)
                self.tableView.reloadData()
            }
        }
        for i in 0..<(self.chat?.group_users?.count ?? 0){
            let fcm = Utils.getUser(user_id: self.chat?.group_users?[i].uid ?? "")?.fcm ?? ""
            Utils.sendNotification(fcm: fcm, event: .message, user: self.chat!.group_users![i], name: Auth.auth().currentUser?.displayName ?? "", user_id: Auth.auth().currentUser?.uid ?? "")
        }
        galleryButton.isHidden = false
        locationButton.isHidden = false
        sendMessageButton.isHidden = true
        messageTF.resignFirstResponder()
        messageTF.text = "Message..."
        messageTF.textColor = UIColor.lightGray
        heightConstraintTextView.constant = 105
    }
    
    func fetchChat(){
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child((isFromShare ? self.chat?.user?.uid ?? "" : user!.uid) ?? "").observe(.value) { (snapshot) in
            self.messages.removeAll()
            
            guard let value = snapshot.value as? [String:Any] else {
                return
            }
            
            value.forEach { (key, value2) in
                var message1 = try! FirebaseDecoder().decode(Message.self, from: value2 as? [String: Any] ?? [:])
                message1.message_id = key
                if message1.message != nil || message1.image_url != nil || message1.video_url != nil{
                    self.messages.append(message1)
                }
            }
            self.messages = self.messages.sorted(by: { (message1, message2) -> Bool in
                guard let time1 = message1.time, let time2 = message2.time else {
                    return false
                }
                return time1 > time2
            })
            self.messages.reverse()
            
            DispatchQueue.main.async {
                if self.messages.count > 1{
                    self.tableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: false)
                }
                
            }
            self.tableView.reloadData()
        }
        
    }
    func otherChats(){
        Database.database().reference().child("chats").child((isFromShare ? self.chat?.user?.uid ?? "" : user!.uid) ?? "").child(Auth.auth().currentUser!.uid).observe(.value) { (snapshot) in
            self.othermessages.removeAll()
            
            guard let value = snapshot.value as? [String:Any] else {
                return
            }
            
            value.forEach { (key, value2) in
                var message1 = try! FirebaseDecoder().decode(Message.self, from: value2 as? [String: Any] ?? [:])
                message1.message_id = key
                if message1.message != nil || message1.image_url != nil || message1.video_url != nil{
                    self.othermessages.append(message1)
                }
            }
            self.othermessages = self.othermessages.sorted(by: { (message1, message2) -> Bool in
                guard let time1 = message1.time, let time2 = message2.time else {
                    return false
                }
                return time1 > time2
            })
            self.othermessages.reverse()
        }
    }
    func setupTextView(){
        messageTF.text = "Message..."
        messageTF.textColor = UIColor.lightGray
        messageTF.delegate = self
    }
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty{
            heightConstraintTextView.constant = 105.0
            return
        }
        if messageTF.text.count > 0 && messageTF.text != "Message..."{
            galleryButton.isHidden = true
            locationButton.isHidden = true
            sendMessageButton.isHidden = false
        }else if messageTF.text.count == 0 && messageTF.text != "Message..."{
            galleryButton.isHidden = false
            locationButton.isHidden = false
            sendMessageButton.isHidden = true
        }
        let layoutManager = textView.layoutManager
        let numberOfLines = layoutManager.lineFragmentRect(forGlyphAt: textView.text.count - 1, effectiveRange: nil).maxY / textView.font!.lineHeight + 1
        
        let contentSize = textView.contentSize
        let previousContentSize = textView.bounds.size
        if contentSize.height > previousContentSize.height && numberOfLines <= 5 {
            let heightDifference = contentSize.height - previousContentSize.height
            heightConstraintTextView.constant = heightConstraintTextView.constant + heightDifference
        }else if contentSize.height < previousContentSize.height {
            let heightDifference = previousContentSize.height - contentSize.height
            heightConstraintTextView.constant = heightConstraintTextView.constant - heightDifference
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = self.isDarkModeEnabled() ? UIColor.white : UIColor.black
        }
        
    }
    func detectLinks(in text: String) -> (Bool?,String?){
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        for match in matches ?? [] {
            if match.resultType == .link {
                print("Link detected: \(match.url?.absoluteString ?? "")")
                return (true,match.url?.absoluteString ?? "")
            }
        }
        return (false,"")
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Message..."
            galleryButton.isHidden = false
            locationButton.isHidden = false
            sendMessageButton.isHidden = true
            heightConstraintTextView.constant = 105.0
            textView.textColor = UIColor.lightGray
        }
    }
    
    deinit{
        removeObservers()
    }
    
    func setView(){
        //        populateData()
        registerNibs()
        mainView.cornerRadius = 35
        mainView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        //        tableView.allowsSelection = false
    }
    
    @IBAction func topHeaderClicked(_ sender: Any) {
        if chat?.is_group ?? false{
            let storyboard = UIStoryboard(name: "Chat", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: GroupSettingsViewController.self)) as! GroupSettingsViewController
            vc.groupData = chat
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func cameraButtonPressed(_ sender: Any) {
        PhotoPicker.shared.delegate = self
        PhotoPicker.shared.capturePhoto(with: self)
        
    }
    @IBAction func mapButtonPressed(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SendLocationViewController.self)) as! SendLocationViewController
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func denyButtonPressed(_ sender: Any) {
        Database.database().reference().child("chats").child(self.user?.uid ?? "").child(Auth.auth().currentUser?.uid ?? "").removeValue { error, ref in
            if error == nil{
                
            }
        }
        Database.database().reference().child("chats").child(Auth.auth().currentUser?.uid ?? "").child(self.user?.uid ?? "").removeValue { error, ref in
            if error == nil{
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    @IBAction func acceptButtonPressed(_ sender: Any) {
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser?.uid ?? "").child(user?.uid ?? "").updateChildValues(["is_request_accepted": true]) { error, red in
            if error == nil{
                self.containerView.isHidden = false
                self.requestView.isHidden = true
            }
        }
    }
    @IBAction func galleryButtonPressed(_ sender: Any) {
        pickMediaFromGallery()
    }
    func pickMediaFromGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePicker, animated: true, completion: nil)
    }
    @IBAction func moreButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .default , handler: { (UIAlertAction) in
            if self.chat?.is_group ?? false{
                Database.database().reference().child("chats").child(self.chat?.group_id ?? "").removeValue { error, ref in
                    if error == nil{
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                
                Utils.logFirebaseEvent(eventName: "did_remove_chat")
            }else{
                Database.database().reference().child("chats").child(self.user?.uid ?? "").child(Auth.auth().currentUser?.uid ?? "").removeValue { error, ref in
                    if error == nil{
                        //                    self.navigationController?.popViewController(animated: true)
                    }
                }
                Database.database().reference().child("chats").child(Auth.auth().currentUser?.uid ?? "").child(self.user?.uid ?? "").removeValue { error, ref in
                    if error == nil{
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
            
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        alert.popoverPresentationController?.sourceView = self.view
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    @IBAction func sendButtonPressed(_ sender: Any) {
        if chat?.is_group ?? false{
            if editMessageIndex != -1{
                self.messages[editMessageIndex].message = messageTF.text ?? ""
                Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["messages": self.messages.map({ message in
                    message.dictionary
                })])
                galleryButton.isHidden = false
                locationButton.isHidden = false
                sendMessageButton.isHidden = true
                messageTF.resignFirstResponder()
                messageTF.text = "Message..."
                messageTF.textColor = UIColor.lightGray
                heightConstraintTextView.constant = 105
                editMessageIndex = -1
                self.tableView.reloadData()
            }else{
                sendGroupMessage()
                Utils.logFirebaseEvent(eventName: "send_group_message")
            }
        }else{
            if editMessageIndex != -1{
                Database.database().reference().child("chats").child(Auth.auth().currentUser?.uid ?? "").child(user?.uid ?? "").child(messages[editMessageIndex].message_id ?? "").updateChildValues(["message" : messageTF.text ?? ""])
                Database.database().reference().child("chats").child(user?.uid ?? "").child(Auth.auth().currentUser?.uid ?? "").child(othermessages[editMessageIndex].message_id ?? "").updateChildValues(["message" : messageTF.text ?? ""])
                galleryButton.isHidden = false
                locationButton.isHidden = false
                sendMessageButton.isHidden = true
                messageTF.resignFirstResponder()
                messageTF.text = "Message..."
                messageTF.textColor = UIColor.lightGray
                heightConstraintTextView.constant = 105
                editMessageIndex = -1
            }else{
                sendMessage()
                Utils.logFirebaseEvent(eventName: "send_message")
            }
        }
    }
    
    func registerNibs(){
        tableView.register(UINib(nibName: String(describing: SendMessageTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: SendMessageTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: ReceiveTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: ReceiveTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: SendImageTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: SendImageTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: ReceiveImageTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: ReceiveImageTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: SendLocationTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: SendLocationTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: ReceiveLocationTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: ReceiveLocationTableViewCell.self))
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
}

extension MessageViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count == 0 ? 0 : messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if messages[indexPath.row].sender_id ?? "" == Auth.auth().currentUser?.uid ?? ""{
            if (messages[indexPath.row].image_url == nil) && (messages[indexPath.row].video_url == nil) && (messages[indexPath.row].location == nil){
                if messages[indexPath.row].is_deleted ?? false{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendMessageTableViewCell.self)) as! SendMessageTableViewCell
                    cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                    cell.lblTime.isHidden = false
                    cell.lblMessage.text = "This message has been deleted!"
                    cell.reactionView.isHidden = true
                    cell.selectionStyle = .none
                    return cell
                }else{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendMessageTableViewCell.self)) as! SendMessageTableViewCell
                    cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                    cell.lblMessage.text = messages[indexPath.row].message
                    cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                    cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                    self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                        let label = UILabel()
                        label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                        cell.stackView.addArrangedSubview(label)
                    })
                    cell.selectionStyle = .none
                    return cell
                }
                
            }else if messages[indexPath.row].video_url != nil && messages[indexPath.row].image_url == nil && messages[indexPath.row].location == nil{
                if messages[indexPath.row].is_deleted ?? false{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendMessageTableViewCell.self)) as! SendMessageTableViewCell
                    cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                    cell.lblTime.isHidden = false
                    cell.lblMessage.text = "This message has been deleted!"
                    cell.reactionView.isHidden = true
                    cell.selectionStyle = .none
                    return cell
                }else{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendImageTableViewCell.self)) as! SendImageTableViewCell
                    cell.playView.isHidden = false
                    cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                    cell.selectionStyle = .none
                    cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                    cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                    self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                        let label = UILabel()
                        label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                        cell.stackView.addArrangedSubview(label)
                    })
                    self.generateThumbnailImage(from: URL(string: messages[indexPath.row].video_url ?? "")!) { (thumbnailImage) in
                        if let thumbnailImage = thumbnailImage {
                            DispatchQueue.main.async {
                                cell.messageImage.image = thumbnailImage
                            }
                        } else {
                            self.alert(title: "Error", message: "Error Gnerating Thumbnail")
                        }
                    }
                    return cell
                }
                
            }else if messages[indexPath.row].location != nil && messages[indexPath.row].video_url == nil && messages[indexPath.row].image_url == nil {
                if messages[indexPath.row].is_deleted ?? false{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendMessageTableViewCell.self)) as! SendMessageTableViewCell
                    cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                    cell.lblTime.isHidden = false
                    cell.lblMessage.text = "This message has been deleted!"
                    cell.reactionView.isHidden = true
                    cell.selectionStyle = .none
                    return cell
                }else{
                    print(indexPath.row)
                    print(Utils.getCurrentTimeMilliseconds() - (messages[indexPath.row].location?.sentTime ?? 0.0))
                    print(messages[indexPath.row].location?.duration ?? 0.0)
                    if (Utils.getCurrentTimeMilliseconds() - (messages[indexPath.row].location?.sentTime ?? 0.0)) < (messages[indexPath.row].location?.duration ?? 0.0){
                        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendLocationTableViewCell.self)) as! SendLocationTableViewCell
                        cell.location = messages[indexPath.row].location
                        cell.locationManagerFunction()
                        cell.lblLocationTime.text = "\(Int(millisecondsToHours(milliseconds: messages[indexPath.row].location?.duration ?? 0.0)))hr\(Int(millisecondsToHours(milliseconds: messages[indexPath.row].location?.duration ?? 0.0)) == 1 ? "" : "s")"
                        cell.lblLocation.text = messages[indexPath.row].location?.address ?? ""
                        cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                        cell.selectionStyle = .none
                        cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                        cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                        self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                            let label = UILabel()
                            label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                            cell.stackView.addArrangedSubview(label)
                        })
                        return cell
                    }else{
                        if messages[indexPath.row].location?.duration == nil{
                            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendLocationTableViewCell.self)) as! SendLocationTableViewCell
                            cell.location = messages[indexPath.row].location
                            cell.locationManagerFunction()
                            cell.timeView.isHidden = true
                            cell.lblLocationTime.text = "\(Int(millisecondsToHours(milliseconds: messages[indexPath.row].location?.duration ?? 0.0)))hr\(Int(millisecondsToHours(milliseconds: messages[indexPath.row].location?.duration ?? 0.0)) == 1 ? "" : "s")"
                            cell.lblLocation.text = messages[indexPath.row].location?.address ?? ""
                            cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                            cell.selectionStyle = .none
                            cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                            cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                            self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                                let label = UILabel()
                                label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                                cell.stackView.addArrangedSubview(label)
                            })
                            return cell
                        }else{
                            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendMessageTableViewCell.self)) as! SendMessageTableViewCell
                            cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                            cell.lblTime.isHidden = false
                            cell.lblMessage.text = "Location Removed"
                            cell.reactionView.isHidden = true
                            cell.selectionStyle = .none
                            return cell
                        }
                    }
                }
            }
            else{
                if messages[indexPath.row].is_deleted ?? false{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendMessageTableViewCell.self)) as! SendMessageTableViewCell
                    cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                    cell.lblTime.isHidden = false
                    cell.lblMessage.text = "This message has been deleted!"
                    cell.reactionView.isHidden = true
                    cell.selectionStyle = .none
                    return cell
                }else{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SendImageTableViewCell.self)) as! SendImageTableViewCell
                    cell.selectionStyle = .none
                    cell.lblTime.text = "✔️ Sent at \(Utils.formatTime(inputTime: messages[indexPath.row].time ?? ""))"
                    cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                    cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                    self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                        let label = UILabel()
                        label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                        cell.stackView.addArrangedSubview(label)
                    })
                    cell.playView.isHidden = true
                    Utils.loadImage(imageView: cell.messageImage, urlString: messages[indexPath.row].image_url ?? "", placeHolder: UIImage(named: "placeholderImage"))
                    return cell
                }
            }
            
        }else{
            if (messages[indexPath.row].image_url == nil) && (messages[indexPath.row].video_url == nil) && (messages[indexPath.row].location == nil){
                if messages[indexPath.row].is_deleted ?? false{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveTableViewCell.self)) as! ReceiveTableViewCell
                    cell.lblMessage.text = "This message has been deleted!"
                    cell.reactionView.isHidden = true
                    if chat?.is_group ?? false{
                        Utils.loadImage(imageView: cell.profileImage, urlString: messages[indexPath.row].sender_user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                        cell.lblName.text = messages[indexPath.row].sender_user?.username ?? ""
                    }else{
                        Utils.loadImage(imageView: cell.profileImage, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                        cell.lblName.text = lblName.text
                    }
                    cell.selectionStyle = .none
                    return cell
                }else{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveTableViewCell.self)) as! ReceiveTableViewCell
                    cell.selectionStyle = .none
                    cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                    cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                    self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                        let label = UILabel()
                        label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                        cell.stackView.addArrangedSubview(label)
                    })
                    cell.lblMessage.text = messages[indexPath.row].message
                    if chat?.is_group ?? false{
                        Utils.loadImage(imageView: cell.profileImage, urlString: messages[indexPath.row].sender_user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                        cell.lblName.text = messages[indexPath.row].sender_user?.username ?? ""
                    }else{
                        Utils.loadImage(imageView: cell.profileImage, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                        cell.lblName.text = lblName.text
                    }
                    return cell
                }
                
            }else if messages[indexPath.row].video_url != nil && messages[indexPath.row].image_url == nil && messages[indexPath.row].location == nil{
                if messages[indexPath.row].is_deleted ?? false{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveTableViewCell.self)) as! ReceiveTableViewCell
                    cell.lblMessage.text = "This message has been deleted!"
                    cell.reactionView.isHidden = true
                    if chat?.is_group ?? false{
                        Utils.loadImage(imageView: cell.profileImage, urlString: messages[indexPath.row].sender_user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                        cell.lblName.text = messages[indexPath.row].sender_user?.username ?? ""
                    }else{
                        Utils.loadImage(imageView: cell.profileImage, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                        cell.lblName.text = lblName.text
                    }
                    cell.selectionStyle = .none
                    return cell
                }else{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveImageTableViewCell.self)) as! ReceiveImageTableViewCell
                    cell.selectionStyle = .none
                    cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                    cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                    self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                        let label = UILabel()
                        label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                        cell.stackView.addArrangedSubview(label)
                    })
                    cell.playView.isHidden = false
                    cell.lblName.text = lblName.text
                    self.generateThumbnailImage(from: URL(string: messages[indexPath.row].video_url ?? "")!) { (thumbnailImage) in
                        if let thumbnailImage = thumbnailImage {
                            
                            DispatchQueue.main.async {
                                cell.messageImage.image = thumbnailImage
                            }
                        } else {
                            self.alert(title: "Error", message: "Error Gnerating Thumbnail")
                        }
                    }
                    return cell
                }
            }else if messages[indexPath.row].location != nil && messages[indexPath.row].video_url == nil && messages[indexPath.row].image_url == nil {
                if messages[indexPath.row].is_deleted ?? false{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveTableViewCell.self)) as! ReceiveTableViewCell
                    cell.lblMessage.text = "This message has been deleted!"
                    cell.reactionView.isHidden = true
                    if chat?.is_group ?? false{
                        Utils.loadImage(imageView: cell.profileImage, urlString: messages[indexPath.row].sender_user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                        cell.lblName.text = messages[indexPath.row].sender_user?.username ?? ""
                    }else{
                        Utils.loadImage(imageView: cell.profileImage, urlString: user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                        cell.lblName.text = lblName.text
                    }
                    cell.selectionStyle = .none
                    return cell
                }else{
                    if Utils.getCurrentTimeMilliseconds() - (messages[indexPath.row].location?.sentTime ?? 0.0) < (messages[indexPath.row].location?.duration ?? 0.0){
                        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveLocationTableViewCell.self)) as! ReceiveLocationTableViewCell
                        cell.location = messages[indexPath.row].location
                        cell.locationManagerFunction()
                        cell.timeView.isHidden = false
                        cell.lblLocationTime.text = "\(Int(millisecondsToHours(milliseconds: messages[indexPath.row].location?.duration ?? 0.0)))hr\(Int(millisecondsToHours(milliseconds: messages[indexPath.row].location?.duration ?? 0.0)) == 1 ? "" : "s")"
                        cell.lblLocation.text = messages[indexPath.row].location?.address ?? ""
                        cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                        cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                        self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                            let label = UILabel()
                            label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                            cell.stackView.addArrangedSubview(label)
                        })
                        cell.selectionStyle = .none
                        return cell
                    }else{
                        if messages[indexPath.row].location?.duration == nil{
                            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveLocationTableViewCell.self)) as! ReceiveLocationTableViewCell
                            cell.location = messages[indexPath.row].location
                            cell.timeView.isHidden = true
                            cell.locationManagerFunction()
                            cell.lblLocationTime.text = "\(Int(millisecondsToHours(milliseconds: messages[indexPath.row].location?.duration ?? 0.0)))hr\(Int(millisecondsToHours(milliseconds: messages[indexPath.row].location?.duration ?? 0.0)) == 1 ? "" : "s")"
                            cell.lblLocation.text = messages[indexPath.row].location?.address ?? ""
                            cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                            cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                            self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                                let label = UILabel()
                                label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                                cell.stackView.addArrangedSubview(label)
                            })
                            cell.selectionStyle = .none
                            return cell
                        }else{
                            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveTableViewCell.self)) as! ReceiveTableViewCell
                            cell.lblMessage.text = "Location Removed"
                            cell.reactionView.isHidden = true
                            cell.selectionStyle = .none
                            return cell
                        }
                        
                    }
                }
            }
            else{
                if messages[indexPath.row].is_deleted ?? false{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveTableViewCell.self)) as! ReceiveTableViewCell
                    cell.lblMessage.text = "This message has been deleted!"
                    cell.reactionView.isHidden = true
                    cell.selectionStyle = .none
                    return cell
                }else{
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReceiveImageTableViewCell.self)) as! ReceiveImageTableViewCell
                    cell.selectionStyle = .none
                    cell.reactionView.isHidden = messages[indexPath.row].reactions == nil
                    cell.stackView.subviews.forEach({ $0.removeFromSuperview() })
                    self.messages[indexPath.row].reactions?.forEach({ (key: String, value: Int) in
                        let label = UILabel()
                        label.text = ReactionType.get(value: String(key.split(separator: "_")[1]))
                        cell.stackView.addArrangedSubview(label)
                    })
                    cell.playView.isHidden = true
                    cell.lblName.text = lblName.text
                    Utils.loadImage(imageView: cell.messageImage, urlString: messages[indexPath.row].image_url ?? "", placeHolder: UIImage(named: "placeholderImage"))
                    return cell
                }
                
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if messages[indexPath.row].image_url != nil || messages[indexPath.row].video_url != nil{
            if messages[indexPath.row].is_deleted ?? false{
                return UITableView.automaticDimension
            }
            return 300
        }else{
            return UITableView.automaticDimension
        }
        
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        messageTF.resignFirstResponder()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if messages[indexPath.row].location != nil && messages[indexPath.row].video_url == nil && messages[indexPath.row].image_url == nil {
            showActionSheet(lat: messages[indexPath.row].location?.latitude ?? 0.0, lng: messages[indexPath.row].location?.longitude ?? 0.0)
        }else if messages[indexPath.row].location == nil && messages[indexPath.row].video_url != nil && messages[indexPath.row].image_url == nil && messages[indexPath.row].message == nil{
            self.playVideo(url: URL(string: self.messages[indexPath.row].video_url!)!)
        }else if messages[indexPath.row].location == nil && messages[indexPath.row].video_url == nil && messages[indexPath.row].image_url != nil && messages[indexPath.row].message == nil{
            let storyboard = UIStoryboard(name: "Post", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: FullScreenPhotoViewController.self)) as! FullScreenPhotoViewController
            vc.imageurl = messages[indexPath.row].image_url ?? ""
            vc.modalPresentationStyle = .formSheet
            self.present(vc, animated: true)
        }else if (messages[indexPath.row].message?.contains("towntalk.com://"))! && messages[indexPath.row].video_url == nil && messages[indexPath.row].image_url == nil && messages[indexPath.row].location == nil{
            
            let postid = messages[indexPath.row].message?.components(separatedBy: "//")
            if postid!.contains(where: { postid in
                postid == ""
            }){
                print("no post")
            }else{
                print("yes")
                
            }
            let userid = postid![1].components(separatedBy: "/")
            let storyboard = UIStoryboard(name: "Post", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
            vc.post_id = userid[0]
            vc.userid = userid[1]
            self.navigationController?.pushViewController(vc, animated: true)
        }else if (self.detectLinks(in: messages[indexPath.row].message ?? "").0 ?? false) && messages[indexPath.row].video_url == nil && messages[indexPath.row].image_url == nil && messages[indexPath.row].location == nil{
            print("hello")
            let storyboard = UIStoryboard(name: "Explore", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: WebViewViewController.self)) as! WebViewViewController
            vc.name = "Web Link"
            vc.url = self.detectLinks(in: messages[indexPath.row].message ?? "").1 ?? ""
            self.navigationController?.pushViewController(vc, animated: true)
            
        }
    }
    func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        
        let vc = AVPlayerViewController()
        vc.player = player
        
        self.present(vc, animated: true) { vc.player?.play() }
    }
}

extension MessageViewController: PhotoPickerDelegate{
    func didFinish(image: UIImage) {
        if chat?.is_group ?? false{
            uploadImageInGroup(image: image)
        }else{
            singleMesasge(image: image)
        }
    }
    func singleMesasge(image: UIImage){
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.uploadImage(child: "message_images", _image: image) {[self] url in
            let data = Message(sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: self.user,image_url: url?.absoluteString ?? "")
            
            Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["last_message" : "Image"])
            Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["last_message" : "Image"])
            
            Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
            Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["time" : Utils.getCurrentDateTime()])
            
            //request
            Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["is_request_accepted" : true])
            Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["is_request_accepted" : chat?.is_request_accepted ?? false])
            
            Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["user" : user!.dictionary])
            
            let sendUser = User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Auth.auth().currentUser?.displayName ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: "")
            Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["user" : sendUser.dictionary])
            
            Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").childByAutoId().setValue(data.dictionary)
            Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).childByAutoId().setValue(data.dictionary)
            let fcm = Utils.getUser(user_id: user?.uid ?? "")?.fcm ?? ""
            Utils.sendNotification(fcm: fcm, event: .message, user: user!, name: Auth.auth().currentUser?.displayName ?? "", user_id: Auth.auth().currentUser?.uid ?? "")
            galleryButton.isHidden = false
            locationButton.isHidden = false
            sendMessageButton.isHidden = true
            messageTF.resignFirstResponder()
            messageTF.text = "Message..."
            messageTF.textColor = UIColor.lightGray
            heightConstraintTextView.constant = 105
        }
    }
    func uploadImageInGroup(image: UIImage){
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.uploadImage(child: "message_images", _image: image) {[self] url in
            let data = Message(sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: self.user,image_url: url?.absoluteString ?? "")
            self.messages.append(data)
            Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["last_message" : "Image"])
            
            Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
            
            
            //            let sendUser = User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Auth.auth().currentUser?.displayName ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: "")
            //            Database.database().reference().child("chats").child(user!.uid).child(Auth.auth().currentUser!.uid).updateChildValues(["user" : sendUser.dictionary])
            
            Database.database().reference().child("chats").child(chat?.group_id ?? "").child("messages").setValue(messages.map({ message in
                message.dictionary
            })) { error, ref in
                if error == nil{
                    self.chat?.messages?.append(data)
                    self.tableView.reloadData()
                }
            }
            for i in 0..<(self.chat?.group_users?.count ?? 0){
                let fcm = Utils.getUser(user_id: self.chat?.group_users?[i].uid ?? "")?.fcm ?? ""
                Utils.sendNotification(fcm:fcm, event: .message, user: self.chat!.group_users![i], name: Auth.auth().currentUser?.displayName ?? "", user_id: Auth.auth().currentUser?.uid ?? "")
            }
            galleryButton.isHidden = false
            locationButton.isHidden = false
            sendMessageButton.isHidden = true
            messageTF.resignFirstResponder()
            messageTF.text = "Message..."
            messageTF.textColor = UIColor.lightGray
            heightConstraintTextView.constant = 105
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
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }else{
                completion(nil)
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }
}
extension MessageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
            if mediaType == kUTTypeImage as String {
                if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    DispatchQueue.main.async {
                        //                        self.didFinish(image: image)
                        //                    }
                        self.navigatForPhoto(image: image)
                    }
                }
            } else if mediaType == kUTTypeMovie as String {
                if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                    DispatchQueue.main.async {
                        self.navigatForVideo(videoURL: videoURL)
                    }
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    func navigatForPhoto(image: UIImage){
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SendPhotoVideoViewController.self)) as! SendPhotoVideoViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        vc.image = image
        self.present(vc, animated: true)
    }
    func navigatForVideo(videoURL: URL){
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: SendPhotoVideoViewController.self)) as! SendPhotoVideoViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        vc.url = videoURL
        self.present(vc, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func uploadVideoURLToDatabase(videoURL: URL) {
        if !Utils.shared.isInternetAvailable(){
            self.alert(title: "Error", message: "No Internet Available")
            return
        }
        MBProgressHUD.showAdded(to: self.view, animated: true)
        do{
            let data = try Data(contentsOf: videoURL)
            let uuid = UUID().uuidString
            let storageRef = Storage.storage().reference().child("videos").child(Auth.auth().currentUser?.uid ?? "").child("\(uuid).mov")
            // Data in memory
            let metadata = StorageMetadata()
            metadata.contentType = "video/quicktime"
            let _ = storageRef.putData(data, metadata: metadata) { metadata, error in
                guard let _ = metadata else {
                    return
                }
                storageRef.downloadURL { url, error in
                    if error == nil{
                        print(url!)
                        guard let url = url else {return}
                        DispatchQueue.main.async {
                            if self.chat?.is_group ?? false{
                                self.sendGroupVideoMessage(url: url)
                            }else{
                                self.sendVideoMessage(url: url)
                            }
                            
                        }
                        
                    }else{
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                }
            }
        }catch {
            MBProgressHUD.hide(for: self.view, animated: true)
            print("Error loading video data: \(error.localizedDescription)")
        }
        
    }
    
    func sendGroupVideoMessage(url: URL){
        let data = Message(sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: self.user,video_url: url.absoluteString)
        messages.append(data)
        Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["last_message" : "Video"])
        
        Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
        
        Database.database().reference().child("chats").child(chat?.group_id ?? "").child("messages").setValue(messages.map({ message in
            message.dictionary
        })) { error, ref in
            if error == nil{
                self.chat?.messages?.append(data)
                self.tableView.reloadData()
            }
        }
        galleryButton.isHidden = false
        locationButton.isHidden = false
        sendMessageButton.isHidden = true
        messageTF.resignFirstResponder()
        messageTF.text = "Message..."
        messageTF.textColor = UIColor.lightGray
        heightConstraintTextView.constant = 105
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    
    func sendVideoMessage(url: URL){
        let data = Message(sender_id: Auth.auth().currentUser?.uid ?? "", receiver_id: user?.uid ?? "", sender_user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), receiver_user: self.user,video_url: url.absoluteString)
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["last_message" : "Video"])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["last_message" : "Video"])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["time" : Utils.getCurrentDateTime()])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["time" : Utils.getCurrentDateTime()])
        
        //request
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["is_request_accepted" : true])
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["is_request_accepted" : chat?.is_request_accepted ?? false])
        
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").updateChildValues(["user" : user!.dictionary])
        
        let sendUser = User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Auth.auth().currentUser?.displayName ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: "")
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).updateChildValues(["user" : sendUser.dictionary])
        
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).child(user!.uid ?? "").childByAutoId().setValue(data.dictionary)
        Database.database().reference().child("chats").child(user!.uid ?? "").child(Auth.auth().currentUser!.uid).childByAutoId().setValue(data.dictionary)
        galleryButton.isHidden = false
        locationButton.isHidden = false
        sendMessageButton.isHidden = true
        messageTF.resignFirstResponder()
        messageTF.text = "Message..."
        messageTF.textColor = UIColor.lightGray
        heightConstraintTextView.constant = 105
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    func generateThumbnailImage(from videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60) // Capture the thumbnail at 1 second
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { (_, thumbnailCGImage, _, _, _) in
            if let thumbnailCGImage = thumbnailCGImage {
                let thumbnailImage = UIImage(cgImage: thumbnailCGImage)
                completion(thumbnailImage)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Context Menu Actions
    
    func deleteMessage(at indexPath: IndexPath) {
        if chat?.is_group ?? false{
            self.messages.remove(at: indexPath.row)
            let messages = self.messages.map { message in
                message.dictionary
            }
            Database.database().reference().child("chats").child(chat?.group_id ?? "").updateChildValues(["messages":messages])
            self.tableView.reloadData()
        }else{
            let message = messages[indexPath.row]
            if message.sender_id == Auth.auth().currentUser?.uid ?? ""{
                let ref1 = Database.database().reference().child("chats").child(Auth.auth().currentUser?.uid ?? "").child(user?.uid ?? "").child(messages[indexPath.row].message_id ?? "")
                ref1.updateChildValues(["is_deleted": true])
                ref1.updateChildValues(["message": "This message has been deleted!"])
                let ref2 = Database.database().reference().child("chats").child(user?.uid ?? "").child(Auth.auth().currentUser?.uid ?? "").child(othermessages[indexPath.row].message_id ?? "")
                ref2.updateChildValues(["is_deleted": true])
                ref2.updateChildValues(["message": "This message has been deleted!"])
            }else{
                let ref2 = Database.database().reference().child("chats").child(Auth.auth().currentUser?.uid ?? "").child(user?.uid ?? "").child(messages[indexPath.row].message_id ?? "")
                ref2.removeValue { error, snapshot in
                    
                }
            }
            let ref3 = Database.database().reference().child("chats").child(Auth.auth().currentUser?.uid ?? "").child(user?.uid ?? "")
            if messages[indexPath.row].message ?? "" == "This message has been deleted!"{
                ref3.updateChildValues(["last_message": ""])
            }else{
                if indexPath.row > 0{
                    if messages.count > 0{
                        ref3.updateChildValues(["last_message": messages[messages.count - 1].message ?? ""])
                    }else{
                        ref3.updateChildValues(["last_message": ""])
                    }
                }else{
                    ref3.updateChildValues(["last_message": ""])
                }
            }
            let ref4 = Database.database().reference().child("chats").child(user?.uid ?? "").child(Auth.auth().currentUser?.uid ?? "")
            if messages[indexPath.row].message ?? "" == "This message has been deleted!"{
                ref4.updateChildValues(["last_message": ""])
            }else{
                if indexPath.row > 0{
                    if messages.count > 0{
                        ref4.updateChildValues(["last_message": messages[messages.count - 1].message ?? ""])
                    }else{
                        ref4.updateChildValues(["last_message": ""])
                    }
                    
                }else{
                    ref4.updateChildValues(["last_message": ""])
                }
            }
        }
    }
    
    func editMessage(at indexPath: IndexPath) {
        if chat?.is_group ?? false{
            self.editMessageIndex = indexPath.row
            let message = messages[indexPath.row]
            
            self.messageTF.becomeFirstResponder()
            self.messageTF.text = message.message
        }else{
            self.editMessageIndex = indexPath.row
            let message = messages[indexPath.row]
            
            self.messageTF.becomeFirstResponder()
            self.messageTF.text = message.message
        }
    }
    func showActionSheet(lat: Double, lng: Double) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let openGoogleMapsAction = UIAlertAction(title: "Open in Google Maps", style: .default) { (_) in
            self.openGoogleMapsNavigation(lat: lat, lng: lng)
        }
        actionSheet.addAction(openGoogleMapsAction)
        
        let openAppleMapsAction = UIAlertAction(title: "Open in Apple Maps", style: .default) { (_) in
            self.openAppleMapsNavigation(lat: lat, lng: lng)
        }
        actionSheet.addAction(openAppleMapsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        // For iPad support
        if let popoverPresentationController = actionSheet.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = self.view.bounds
        }
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    func openGoogleMapsNavigation(lat: Double, lng: Double) {
        if let url = URL(string: "comgooglemaps://?center=\(lat),\(lng)") {
               if UIApplication.shared.canOpenURL(url) {
                   UIApplication.shared.open(url, options: [:], completionHandler: nil)
               } else {
                   // If Google Maps app is not installed, open in Safari
                   if let webURL = URL(string: "https://maps.google.com/?q=\(lat),\(lng)") {
                       UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
                   }
               }
           }
    }
    
    func openAppleMapsNavigation(lat: Double, lng: Double) {
        let latitude = lat // Replace with your desired latitude
        let longitude = lng // Replace with your desired longitude
        
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
}

extension MessageViewController{
    @available(iOS 13.0, *)
    func createContextMenu(index: Int) -> UIMenu {
        let edit = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")) {_ in
            self.editMessage(at: IndexPath(row: index, section: 0))
        }
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) {_ in
            self.deleteMessage(at: IndexPath(row: index, section: 0))
        }
        if messages[index].sender_id == Auth.auth().currentUser?.uid {
            if messages[index].is_deleted ?? false || messages[index].image_url != nil || messages[index].video_url != nil || messages[index].location != nil{
                return UIMenu(title: "", children: [delete])
            }else{
                return UIMenu(title: "", children: [edit, delete])
            }
            
        }else{
            return UIMenu(title: "", children: [delete])
        }
        
    }
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let identifier = NSString(string: "\(indexPath.row)")
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return UIMenu() }
            return self.createContextMenu(index: indexPath.row)
        }
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        makeTargetedPreview(for: configuration)
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        makeTargetedDismissPreview(for: configuration)
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.preferredCommitStyle = .pop
    }
    
    @available(iOS 13.0, *)
    func makeTargetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String else { return nil }
        guard let row = Int(identifier) else { return nil }
        if let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? SendMessageTableViewCell {
            if messages[row].is_deleted ?? false{
                return nil
            }else{
                return returnCell(cell: cell, row: row)
            }
            
        }else if let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? SendLocationTableViewCell {
            if messages[row].is_deleted ?? false{
                return nil
            }else{
                return returnCell(cell: cell, row: row)
            }
        }else if let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? SendImageTableViewCell {
            if messages[row].is_deleted ?? false{
                return nil
            }else{
                return returnCell(cell: cell, row: row)
            }
        }else if let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? ReceiveTableViewCell {
            if messages[row].is_deleted ?? false{
                return nil
            }else{
                return returnCell(cell: cell, row: row)
            }
            
        }else if let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? ReceiveImageTableViewCell {
            if messages[row].is_deleted ?? false{
                return nil
            }else{
                return returnCell(cell: cell, row: row)
            }
        }else if let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? ReceiveLocationTableViewCell {
            if messages[row].is_deleted ?? false{
                return nil
            }else{
                return returnCell(cell: cell, row: row)
            }
        }
        else{ return nil }
        
    }
    func returnCell(cell: UITableViewCell, row: Int) -> UITargetedPreview?{
        guard let snapshot = cell.resizableSnapshotView(from: CGRect(origin: .zero,
                                                                     size: CGSize(width: cell.bounds.width, height: min(cell.bounds.height, UIScreen.main.bounds.height - reactionHeight - spaceReactionHeight - menuHeight))),
                                                        afterScreenUpdates: false,
                                                        withCapInsets: UIEdgeInsets.zero) else { return nil }
        
        let reactionView = ReactionView()
        reactionView.onReaction = { [weak self] reaction in
            
            guard let self = self else { return }
            
            let reactionType = "\(Auth.auth().currentUser?.uid ?? "")_\(String(String(reflecting: reaction).split(separator: ".")[2]))"
            var reactions = self.messages[row].reactions ?? [:]
            
            reactions.forEach { (key: String, value: Int) in
                if String(key.split(separator: "_")[0]) == Auth.auth().currentUser?.uid ?? "" && String(key.split(separator: "_")[1]) != String(String(reflecting: reaction).split(separator: ".")[2])  {
                    reactions[key] = nil
                }
            }
            
            let isAnyRectionDone = reactions.contains { (key: String, value: Int) in
                String(key.split(separator: "_")[0]) == Auth.auth().currentUser?.uid ?? ""
            }
            
            if(!isAnyRectionDone) {
                reactions[reactionType] = (self.messages[row].reactions[reactionType] as? Int ?? 0) + 1
            }else {
                reactions[reactionType] = nil
            }
            
            if self.chat?.is_group ?? false{
                print(self.chat?.group_id ?? "")
                print(self.messages.count)
                self.chat?.messages?[row].reactions = reactions
                Database.database().reference().child("chats").child(self.chat?.group_id ?? "").child("messages").updateChildValues(self.chat?.messages.map({ message in
                    message.dictionary
                }) ?? [:])
            }else{
                Database.database().reference().child("chats").child(Auth.auth().currentUser?.uid ?? "").child(self.user?.uid ?? "").child(self.messages[row].message_id ?? "").updateChildValues(["reactions": reactions]) { error, ref in
                    
                }
                Database.database().reference().child("chats").child(self.user?.uid ?? "").child(Auth.auth().currentUser?.uid ?? "").child(self.othermessages[row].message_id ?? "").updateChildValues(["reactions": reactions]) { error, ref in
                    
                }
            }
            
            
            
            self.dismiss(animated: true)
        }
        reactionView.layer.cornerRadius = 10
        reactionView.layer.masksToBounds = true
        reactionView.translatesAutoresizingMaskIntoConstraints = false
        
        snapshot.layer.cornerRadius = 10
        snapshot.layer.masksToBounds = true
        snapshot.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView(frame: CGRect(origin: .zero,
                                             size: CGSize(width: cell.bounds.width,
                                                          height: snapshot.bounds.height + reactionHeight + spaceReactionHeight)))
        container.backgroundColor = .clear
        container.addSubview(reactionView)
        container.addSubview(snapshot)
        
        snapshot.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        snapshot.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        snapshot.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        snapshot.bottomAnchor.constraint(equalTo: reactionView.topAnchor, constant: -spaceReactionHeight).isActive = true
        
        reactionView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10).isActive = true
        reactionView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        reactionView.widthAnchor.constraint(equalToConstant: 50*4).isActive = true
        reactionView.heightAnchor.constraint(equalToConstant: reactionHeight).isActive = true
        
        let centerPoint = CGPoint(x: cell.center.x, y: cell.center.y)
        let previewTarget = UIPreviewTarget(container: tableView, center: centerPoint)
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        if #available(iOS 14.0, *) {
            parameters.shadowPath = UIBezierPath()
        }
        return UITargetedPreview(view: container, parameters: parameters, target: previewTarget)
    }
    
    @available(iOS 13.0, *)
    func makeTargetedDismissPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String else { return nil }
        guard let row = Int(identifier) else { return nil }
        guard let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? SendMessageTableViewCell else { return nil }
        guard let snapshot = cell.resizableSnapshotView(from: CGRect(origin: .zero,
                                                                     size: CGSize(width: cell.bounds.width, height: min(cell.bounds.height, UIScreen.main.bounds.height - reactionHeight - spaceReactionHeight - menuHeight))),
                                                        afterScreenUpdates: false,
                                                        withCapInsets: UIEdgeInsets.zero) else { return nil }
        
        let centerPoint = CGPoint(x: cell.center.x, y: cell.center.y)
        let previewTarget = UIPreviewTarget(container: tableView, center: centerPoint)
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        if #available(iOS 14.0, *) {
            parameters.shadowPath = UIBezierPath()
        }
        return UITargetedPreview(view: snapshot, parameters: parameters, target: previewTarget)
    }
}
extension MessageViewController: GroupSettingsViewControllerDelegate{
    func updateUserList(chat: Chat) {
        self.chat = chat
    }
}
extension MessageViewController: SendLocationViewControllerDelegate{
    func sendLocationWithTime(location: CurrentLocation) {
        if chat?.is_group ?? false{
            sendGroupLocation()
        }else{
            sendLocation(location: location)
        }
    }
    func millisecondsToHours(milliseconds: Double) -> Double {
        let millisecondsPerHour: Double = 60 * 60 * 1000
        return milliseconds / millisecondsPerHour
    }
}

extension MessageViewController: SendPhotoVideoViewControllerDelegate{
    func sendPhoto(image: UIImage) {
        DispatchQueue.main.async {
            self.didFinish(image: image)
        }
    }
    func sendVideo(url: URL) {
        DispatchQueue.main.async {
            self.uploadVideoURLToDatabase(videoURL: url)
        }
    }
}
