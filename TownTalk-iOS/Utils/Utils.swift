//
//  Login.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//

import Foundation
import UIKit
import SystemConfiguration
import SDWebImage
import AVFAudio
import AVFoundation
import LocalAuthentication
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase
import FirebaseAnalytics

class Utils: NSObject{
    
    static let shared = Utils()
    var isPortrait: Bool = true
    static var user: User?
    var isiPhone: Bool{
        return (UIDevice.current.userInterfaceIdiom == .phone)
    }
    static var feeds = [Feed]()
    static func fetchCurrentUser(){
        Database.database().reference().child(FirebaseKeys.userTable).observeSingleEvent(of: .value, with: { snapshot in
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    if key == Auth.auth().currentUser?.uid ?? ""{
                        let user = try! FirebaseDecoder().decode(User.self, from: value)
                        self.user = user
                    }
                }
            }
        })
    }
    static func isUserBlocked(userID: String, completionHandler: @escaping (Bool) -> Void){
        Database.database().reference().child("blocked_users").child(Auth.auth().currentUser?.uid ?? "").child(userID).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completionHandler(true)
            }else{
                completionHandler(false)
            }
        }
    }
    
    static func isPostReported(postID: String, completionHandler: @escaping (Bool) -> Void){
        Database.database().reference().child("reports").child(Auth.auth().currentUser?.uid ?? "").child(postID).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completionHandler(true)
            }else{
                completionHandler(false)
            }
        }
    }
    static func isDarkModeEnabled(for traitCollection: UITraitCollection) -> Bool {
        if #available(iOS 13.0, *) {
            let userInterfaceStyle = traitCollection.userInterfaceStyle
            if userInterfaceStyle == .dark {
                // Dark mode is enabled
                return true
            } else {
                // Light mode is enabled
                return false
            }
        }
        // Fallback for older iOS versions
        return false
    }


    static func logFirebaseEvent(eventName: String) {
        
        Analytics.logEvent(eventName, parameters: [
            "event_name": eventName
        ])
    }
    
    static func addNotification(user_id: String, post_id: String,event: EventNotification, sender_user_id: String? = nil){
        let notificationModel = AppNotification(user_id: Auth.auth().currentUser?.uid ?? "", post_id: post_id, event: event.rawValue,sender_user_id: user_id)
        Database.database().reference().child("notifications").child(user_id).childByAutoId().setValue(notificationModel.dictionary)
    }
    static func addNotificationForTag(user_id: String, post_id: String,event: EventNotification, sender_user_id: String? = nil){
        let notificationModel = AppNotification(user_id: sender_user_id, post_id: post_id, event: event.rawValue,sender_user_id: sender_user_id)
        Database.database().reference().child("notifications").child(user_id).childByAutoId().setValue(notificationModel.dictionary)
    }
    
    static func addTown(_ town: Town) {
        Database.database().reference().child("towns").observeSingleEvent(of: .value) { snapshot in
            if var value = snapshot.value as? [[String:Any]] {
                // Check if the town already exists in the list
                let existingTown = value.first { dict in
                    if let name = dict["name"] as? String {
                        return name == town.name
                    }
                    return false
                }
                
                if existingTown == nil {
                    // Add the new town to the list
                    let newTown = [
                        "name": town.name ?? "",
                        "noOfCheckIns": town.noOfCheckIns ?? 0,
                        "lat": town.lat ?? 0.0,
                        "lng": town.lng ?? 0.0
                    ]
                    value.append(newTown)
                    
                    // Update the towns list in the database
                    Database.database().reference().child("towns").setValue(value)
                }
            }else{
                var townArray = [Town]()
                townArray.append(town)
                Database.database().reference().child("towns").setValue(townArray.map({ town in
                    town.dictionary
                }))
            }
        }
    }
    static func getUser(user_id: String) -> User?{
        let matchingUsers = Constants.users.filter { $0.uid == user_id }
        return matchingUsers.first
    }
    
    static func isReported(post_id: String) -> Bool?{
        return Constants.reports.contains {
            $0.post?.post_id == post_id
        }
    }
    static func isBlocked(user_id: String) -> Bool?{
        return Constants.blockedUsers.contains {
            $0.uid == user_id
        }
    }
    static func getCurrentTimeMilliseconds() -> Double {
        let currentTime = Date().timeIntervalSince1970
        let currentTimeMilliseconds = Int64(currentTime * 1000)
        return Double(currentTimeMilliseconds)
    }
    static func getFeedsForCurrentUser(onCompletion: @escaping ([Feed]) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            onCompletion([Feed]())
            return
        }
        let usersRef = Database.database().reference().child("users")
        let currentUserRef = usersRef.child(currentUserID)
        
        currentUserRef.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any],
                  let feedsData = userData["feeds"] as? [[String: Any]] else {
                onCompletion([Feed]())
                return
            }
            for feedData in feedsData {
                let feedName = feedData["feed_name"] as? String ?? ""
                let feedID = feedData["id"] as? Int ?? 0
                
                let feed = Feed(feed_name: feedName,id: feedID)
                self.feeds.append(feed)
                onCompletion(self.feeds)
            }
        } withCancel: { error in
            print("Error fetching feeds for current user: \(error.localizedDescription)")
            onCompletion([Feed]())
            return
        }
    }
    
    static func initiateUser() -> User{
        let user = User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Utils.user?.username ?? "", email: Auth.auth().currentUser?.email ?? "", phone: Auth.auth().currentUser?.phoneNumber ?? "", zip_code: "",fullName: Auth.auth().currentUser?.displayName ?? "")
        return user
    }
    
    static func sendNotification(fcm: String,event: EventNotification,user: User,name: String,post_id: String? = nil, user_id: String){
        var body = ""
        switch event{
        case .like:
            body = "\(name) liked your post"
        case .comment:
            body = "\(name) commented on your post"
        case .post_tag:
            body = "\(name) tagged you on a post"
        case .comment_like:
            body = "\(name) liked your comment"
        case .comment_mention:
            body = "\(name) mentioned you in a comment"
        case .message:
            body = "\(name) sent you a message"
        default:
            break
        }
        let message = [
            "to": fcm,
            "notification": [
                "title": "Town Talk",
                "body": body,
                "sound": "default",
                "show_in_foreground": true,
                "priority": "high",
                "content_available": true,
            ],
            "data": [
                "post_id": post_id ?? "",
                "user_id": user_id
            ],
        ] as [String : Any]

        let serverKey = Constants.serverKey

        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")

        let jsonData = try! JSONSerialization.data(withJSONObject: message, options: [])

        let task = URLSession.shared.uploadTask(with: request, from: jsonData) { _, _, error in
            if let error = error {
                print("Error sending notification: \(error)")
            } else {
                print("Notification sent successfully")
            }
        }

        task.resume()

    }
    
    static func getAllUsers(completion: @escaping ([User]) -> Void) {
        var users = [User]()
        let usersRef = Database.database().reference().child("users")
        usersRef.observeSingleEvent(of: .value, with: { snapshot in
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    var user = try! FirebaseDecoder().decode(User.self, from: value)
                    user.uid = key
                    if Utils.isBlocked(user_id: user.uid ?? "") ?? false == true {
                        
                    }else{
                        if user.is_deleted ?? false{
                            
                        }else{
                            users.append(user)
                        }
                        
                    }
                    
                }
                completion(users)
            }
        }) { error in
            print(error.localizedDescription)
            completion([])
        }
    }
    
    
    
    
    
    
    static func checkUsersHaveFeedCount( userKey:String ,completion: @escaping (Int?) -> Void) {
        let usersRef = Database.database().reference().child("users").child(userKey)
        usersRef.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.hasChild("feedCount") {
                    // "feedCount" field exists, get its value
                    if let feedCount = snapshot.childSnapshot(forPath: "feedCount").value as? Int {
                        print("User has feedCount: \(feedCount)")
                        completion(feedCount)
                    } else {
                        print("The value of feedCount is not in the expected format.")
                        completion(nil)
                    }
                } else {
                    print("User does not have a feedCount field.")
                    completion(nil)
                }
           
        }) { error in
            print(error.localizedDescription)
            completion(nil)
        }
    }
    
    
    static func updateUserFeedCount( userKey:String , feedCount:Int, completion: @escaping (Bool) -> Void) {
        
        
        let usersRef = Database.database().reference().child("users").child(userKey)
        let newData: [String: Any] = [
             "feedCount": feedCount
        ]
         // Update the existing record with the new data
          usersRef.updateChildValues(newData) { (error, reference) in
             if let error = error {
                 print("\(error.localizedDescription)")
                 completion(false)
             } else {
                 completion(true)
             }
         }
        
    
    }
    
    
    
    
    
    
    
    
    static func formatTime(inputTime: String) -> String {
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        guard let date = inputDateFormatter.date(from: inputTime) else {
            print("Failed to parse the input time.")
            return ""
        }
        
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateFormat = "h:mm a" // Use "H:mm" for 24-hour format
        
        let formattedTime = outputDateFormatter.string(from: date)
        
        return(formattedTime)
    }
    
    static func isEmailExistInFirebase(email: String, onCompletion: @escaping (Bool) -> Void){
        let databaseReff = Database.database().reference().child("users")
        databaseReff.queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.value, with: { snapshot in
            if snapshot.exists(){
                onCompletion(true)
            }else{
                onCompletion(false)
            }
        })
    }
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    static func getDaysAgo(postDate: String) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let pastDate = formatter.date(from: postDate) ?? Date()
        let currentDate = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: pastDate, to: currentDate)
        let daysAgo = components.day!
        if daysAgo == 0{
            return "Today"
        }else{
            if daysAgo > 1{
                return "\(daysAgo) days ago"
            }else{
                return "\(daysAgo) day ago"
            }
        }
    }
    
    static func getCurrentDateTime() -> String{
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateString = formatter.string(from: currentDate)
        return currentDateString
    }
    static func addChildController(vc: UIViewController,parent: UIViewController, containerView: UIView){
        vc.willMove(toParent: parent)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(vc.view)
        parent.addChild(vc)
        vc.didMove(toParent: parent)
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            vc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    static func removeChildController(vc: UIViewController?){
        if (vc != nil && vc!.parent != nil){
            vc!.willMove(toParent: nil)
            vc!.view.removeFromSuperview()
            vc!.removeFromParent()
            vc!.didMove(toParent: nil)
        }
    }
    func isPortrait(size: CGSize) -> Bool{
        return (size.width < size.height)
    }
    
    func isInternetAvailable() -> Bool{
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    func convertStringPriceToNSNumber(price: String) -> NSNumber{
        let price: Float = Float((price.components(separatedBy: "$") as NSArray).object(at: 1) as! String)!
        return NSNumber(value: price)
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
    
    func layoutIfNeededWithAnimation(view: UIView){
        UIView.animate(withDuration: 0.3) {
            view.layoutIfNeeded()
        }
    }
    
    func removeSpaceFromURL(string : String) -> String{
        let trimmedString = string.trimmingCharacters(in: .whitespaces)
        return trimmedString
    }
    func layoutIfNeededWithAnimation(view: UIView, withDuration: TimeInterval){
        
        UIView.animate(withDuration: withDuration, animations: {
            view.layoutIfNeeded()
        })
    }
    
    static func loadImage(imageView: UIImageView, urlString: String, placeHolderImageString: String?)->Swift.Void{
        let placeHolder = UIImage(named: placeHolderImageString ?? "")
        imageView.image = placeHolder
        let encodedString:String = urlString.replacingOccurrences(of: " ", with: "%20")
        
        imageView.sd_setImage(with: URL(string: encodedString), placeholderImage: placeHolder)
    }
    
    static func loadImage(imageView: UIImageView, urlString: String, placeHolder: UIImage?)->Swift.Void{
        imageView.image = placeHolder
        let encodedString:String = urlString.replacingOccurrences(of: " ", with: "%20")
        
        imageView.sd_setImage(with: URL(string: encodedString), placeholderImage: placeHolder)
    }
    
    static func loadImageAndRender(imageView: UIImageView, urlString: String, placeHolderImageString: String?)->UIImage?{
        var img: UIImage?
        let stringInUrlFormat = URL.init(string: urlString)
        
        SDWebImageDownloader.self().downloadImage(with: stringInUrlFormat, options: SDWebImageDownloaderOptions.useNSURLCache, progress: { (receivedSize, expectedSize, stringInUrlFormat) in
            //code here
        }) { (image, data, error, finished)  in
            if ((image != nil) && finished){
                imageView.image = image?.withRenderingMode(.alwaysOriginal)
            }
            img = image
        }
        return img
    }
    
    static func loadImageWithRender(imageView: UIImageView, urlString: String, placeHolderImageString: String?)->Swift.Void{
        let placeHolder = UIImage(named: placeHolderImageString ?? "")?.withRenderingMode(.alwaysTemplate)
        imageView.image = placeHolder
        let encodedString:String = urlString.replacingOccurrences(of: " ", with: "%20")
        
        imageView.sd_setImage(with: URL(string: encodedString), placeholderImage: placeHolder)
        //imageView.image?.withRenderingMode(.alwaysTemplate)
        
    }
    
    static func animateLabel(label : UILabel!){
        UIView.animate(withDuration: 0.2) {
            let scaleTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            let translateTransform = CGAffineTransform(translationX: -45, y: -20)
            let comboTransform = scaleTransform.concatenating(translateTransform)
            label.transform = comboTransform
        }
    }
    static func animateBack(label : UILabel!){
        if(label.text == DefaultValue.string){
            UIView.animate(withDuration: 0.2) {
                label.transform = CGAffineTransform.identity
            }
        }
    }
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    
    // MARK: - checkCamera Permissions
    static func isCameraPermissionAlowed() -> Bool{
        var isAllow = false
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            isAllow = true
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    isAllow = true
                } else {
                    isAllow = false
                }
            })
        }
        return isAllow
    }
    
    
    static func saveAccountInLoggedInUser(userList:[UserObjectSP]){
        // Encode the array into Data
        if let encodedData = try? JSONEncoder().encode(userList) {
            UserDefaults.standard.set(encodedData, forKey: "userListKey")
        }
    }
    
    static func getAccountsWhoInLoggedin() ->  [UserObjectSP] {
        // Encode the array into Data
        var userObjectSPList:  [UserObjectSP]  = []
        if let storedData = UserDefaults.standard.data(forKey: "userListKey"),
           let decodedList = try? JSONDecoder().decode([UserObjectSP].self, from: storedData) {
            // You have your list of UserObjects back
            for user in decodedList {
                print("UserID: \(user.user_id), Username: \(user.username)")
            }
        userObjectSPList = decodedList
        }
        return userObjectSPList
    }
    
    //Check User Is Saved Already :
    
    
    static  func checkUserSavedInSharedPrefrences(email:String) -> Bool{
        var savedUsers:[UserObjectSP] = Utils.getAccountsWhoInLoggedin()
        var isSaved = savedUsers.contains(where: { $0.email == email })
        return isSaved
        }
    
    
    static var zodiacSignList = [ZodiacSignModel]()

    static  func setAZodiacSignsList(){
        
        zodiacSignList.append(ZodiacSignModel(name: "Aries – March 21st – April 19th",
                                              description: "Independent and strong‒willed, you are a force to be reckoned with! You love nothing more than an exciting new goal to tackle, and you do your best work when you’re flying solo. Your passion and energy keep the rest of us on our toes!",
                                              career: 85,
                                              love: 75,
                                              luck: 90,
                                              family: 70,
                                              business: 80,
                                              isSlected: false,
                                              image: "aries"))
        zodiacSignList.append(ZodiacSignModel(name: "Taurus - April 20th – May 20th",
                                              description: "As a Taurus, you’re a wonderful combination of laid‒back and hard‒working. You’re honest and loyal, occasionally to a fault. Your determination and attention to detail will take you far in life.",
                                              career: 80,
                                              love: 85,
                                              luck: 70,
                                              family: 90,
                                              business: 75,
                                              isSlected: false,
                                              image: "taurus"))
        zodiacSignList.append(ZodiacSignModel(name: "Gemini – May 21st – June 20th",
                                              description: "Your ability to have a good relationship with a wide variety of people makes you a bit of a social butterfly, but you’ll take advantage of some alone time when it comes your way. Curious and deeply emotional, you love ritual and celebration",
                                              career: 70,
                                              love: 90,
                                              luck: 75,
                                              family: 80,
                                              business: 85,
                                              isSlected: false,
                                              image: "gemini"))
        zodiacSignList.append(ZodiacSignModel(name: "Cancer – June 21st – July 22nd",
                                              description: "Your intuition is downright uncanny! You do your best socializing in small groups and prefer intimate relationships even if it means your social circle is on the smaller side. Your creative spirit will bring joy to all you meet.",
                                              career: 75,
                                              love: 95,
                                              luck: 80,
                                              family: 95,
                                              business: 70,
                                              isSlected: false,
                                              image: "cancer"))
        zodiacSignList.append(ZodiacSignModel(name: "Leo - July 23rd – August 22nd",
                                              description: "It’s no wonder your symbol is a lion. Your personality and presence are impressive to all. This may intimidate some, but your inviting spirit will help you easily make friends",
                                                 career: 90,
                                              love: 80,
                                              luck: 95,
                                              family: 85,
                                              business: 90,
                                              isSlected: false,
                                              image: "leo"))
        zodiacSignList.append(ZodiacSignModel(name: "Virgo – August 23rd – September 22nd",
                                              description: "You are the picture of poise and elegance. You love to stay organized and have a strong focus on keeping things aesthetic. But you’re not just beauty. You’ve got brains, too! You’ll continue seeking knowledge and intellectual growth as you age",
                                              career: 85,
                                              love: 70,
                                              luck: 75,
                                              family: 80,
                                              business: 95,
                                              isSlected: false,
                                              image: "virgo"))
        zodiacSignList.append(ZodiacSignModel(name: "Libra – September 23rd – October 22nd",
                                              description: "You have a large social circle, and your open‒mindedness helps you get along with just about anyone. But don’t get lost in the crowd! A focus on self‒care and personal reflection will help you build your confidence over time.",
                                              career: 80,
                                              love: 95,
                                              luck: 90,
                                              family: 85,
                                              business: 70,
                                              isSlected: false,
                                              image: "libra"))
        zodiacSignList.append(ZodiacSignModel(name: "Scorpio – October 23rd - November 21st",
                                              description: "As a Scorpio, you can have a sharp edge, but this isn’t always a negative quality. It gives you an appreciation for authenticity and a strong sense of independence. However, you’re not always as tough as you appear. Once you let people into your life, you’re a bit of a softy.",
                                              career: 90,
                                              love: 75,
                                              luck: 70,
                                              family: 80,
                                              business: 85,
                                              isSlected: false,
                                              image: "scorpio"))
        zodiacSignList.append(ZodiacSignModel(name: "Sagittarius — November 22nd - December 21st",
                                              description: "The road less traveled is your favorite place to be! Your bravery is admirable and will make you a good fit for leadership roles. You also have a bit of an itch in your shoes and will always be ready to take on a new adventure.",
                                              career: 75,
                                              love: 90,
                                              luck: 85,
                                              family: 70,
                                              business: 80,
                                              isSlected: false,
                                              image: "sagittarius"))
        zodiacSignList.append(ZodiacSignModel(name: "Capricorn — December 22nd - January 19th",
                                              description: "Your perfectionism and high standards, though sometimes an obstacle, can be one of your superpowers when handled wisely. You have a strong sense of self, which enables you to make meaningful connections and lead the way",
                                              career: 95,
                                              love: 80,
                                              luck: 70,
                                              family: 90,
                                              business:95,
                                              isSlected: false,
                                              image: "capricorn"))
        zodiacSignList.append(ZodiacSignModel(name: "Aquarius — January 20th - February 18th",
                                              description: "You may fall on the introvert side of the spectrum, but that doesn’t mean you don’t know how to have fun. You have an enviable combination of intelligence and intuition, and you are able to identify positive opportunities even in dark times.",
                                              career: 80,
                                              love: 85,
                                              luck: 75,
                                              family: 70,
                                              business: 90,
                                              isSlected: false,
                                              image: "aquarius"))
        
        zodiacSignList.append(ZodiacSignModel(name: "Pisces — February 19th - March 20th",
                                              description: "You wouldn’t hurt a fly! Empathy is your superpower, and you are an asset to any team you join or cause you support. Your gentleness is a virtue. However, be careful to not let your feelings get hurt too easily. Be sure to spend time building your self‒confidence.",
                                              career: 70,
                                              love: 95,
                                              luck: 90,
                                              family: 85,
                                              business: 80,
                                              isSlected: false,
                                              image: "pisces"))

    }

    
    

    
}
extension UIImage {
    func imageWithColor(_ color: UIColor) -> UIImage? {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.set()
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIButton {
    func underline(forTitle: String) {
        let attributedString = NSMutableAttributedString(string: forTitle)
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: (forTitle.count)))
        self.setAttributedTitle(attributedString, for: .normal)
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension NSObject{
    class var className: String{
        return String(describing: self.self)
    }
}

extension Optional{
    var isSome: Bool{
        return self != nil
    }
    
    var isNone: Bool{
        return self == nil
    }
}

extension UIViewController {
    func showAlertToChooseAction(title: String, message : String, finished completion: @escaping() -> Void, cancelled: @escaping() -> Void,cancelTitle: String, finishTitle: String ){
        let ac = UIAlertController(title: title, message: message , preferredStyle: .alert)
        let cancelAction = UIAlertAction.init(title: cancelTitle, style: .default, handler: { (action) in
            ac.dismiss(animated: true, completion: nil)
            cancelled()
        })
        let emailSupport = UIAlertAction.init(title: finishTitle, style: .default, handler: { (action) in
            completion()
        })
        ac.addAction(cancelAction)
        ac.addAction(emailSupport)
        present(ac, animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

/**
 * Dictionary addition operator.
 */
func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left[k] = v
    }
}







struct UserObjectSP: Codable {
    let user_id: String
    let username: String
    let email: String
    let userImage:String
    let normal:Bool
    let gmail:Bool
    let facebook:Bool
    let apple:Bool
}
