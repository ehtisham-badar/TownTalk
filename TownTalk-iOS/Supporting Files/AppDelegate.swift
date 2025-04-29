//
//  AppDelegate.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 19/03/2023.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import Firebase
import FBSDKCoreKit
import FirebaseAuth
import IQKeyboardManagerSwift
import GoogleMaps
import GooglePlaces
import FirebaseDatabase
import CodableFirebase
import FirebaseMessaging
import UserNotifications


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        if let appDomain = Bundle.main.bundleIdentifier {
//           UserDefaults.standard.removePersistentDomain(forName: appDomain)
//        }
        
        Utils.setAZodiacSignsList()
        GMSPlacesClient.provideAPIKey(Constants.GOOGLE_API_KEY)
        
        GMSServices.provideAPIKey(Constants.GOOGLE_API_KEY)
        UserDefaults.standard.set(false, forKey: "appLaunch")
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
        Utils.fetchCurrentUser()
        if let url = URL(string: "towntalk.com://") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
                // Show the app's signed-out state.
            } else {
                // Show the app's signed-in state.
            }
        }
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        //        fetchBlocksedUsers()
        fetchAllUsers()
        blockedUsers()
        fetchReports()
        logAppOpenEvent()
        
        return true
    }
    
    private func logAppOpenEvent() {
        
        Utils.logFirebaseEvent(eventName: "app_open")
        
        if UserDefaults.standard.value(forKey: "isLogInstall") == nil {
            Utils.logFirebaseEvent(eventName: "app_install")
            UserDefaults.standard.setValue(true, forKey: "isLogInstall")
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("url")
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    func applicationWillTerminate(_ application: UIApplication) {
        
    }
    func fetchBlockedUsers(){
        Database.database().reference().child("blocked_users").child(Auth.auth().currentUser?.uid ?? "").observe(.value) { snapshot in
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
    func fetchReports(){
        Database.database().reference().child("reports").observe(.value) { snapshot in
            Constants.reports.removeAll()
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    if let value = value as? [String:Any]{
                        value.forEach { (key: String, value: Any) in
                            let report = try! FirebaseDecoder().decode(Report.self, from: value)
                            Constants.reports.append(report)
                        }
                    }
                }
            }
        }
    }
    func blockedUsers(){
        Database.database().reference().child("blocked_users").observe(.value) { snapshot in
            Constants.blockedUsers.removeAll()
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    if let value = value as? [String:Any]{
                        value.forEach { (key: String, value: Any) in
                            var user = try! FirebaseDecoder().decode(User.self, from: value)
                            user.uid = key
                            Constants.blockedUsers.append(user)
                        }
                    }
                }
            }
        }
    }
    func isDarkModeEnabled() -> Bool {
        if UserDefaults.standard.bool(forKey: "darkmode") == true{
            return true
        }else{
            return false
        }
    }
    
}
extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        Utils.logFirebaseEvent(eventName: "did_click_notification")
        print(response)
        let userInfo = response.notification.request.content.userInfo
        if let postData = userInfo["post_id"] as? String, let userID = userInfo["user_id"] as? String {
            Constants.isFromCustomURL = true
            print("Received post_id:", postData)
            let post = ["user_id": userID, "post_id": postData]
            if postData == ""{
                    let message = ["user_id": userID]
                    NotificationCenter.default.post(Notification(name: Notification.Name("open_message"),userInfo: message))
                Constants.messageid = userID
            }else{
                NotificationCenter.default.post(Notification(name: Notification.Name("deep_link"),userInfo: post))
            }
            
        }else{
            if let user = userInfo["user_id"] as? String {
                Constants.messageid = user
                let message = ["user": user]
                NotificationCenter.default.post(Notification(name: Notification.Name("open_message"),userInfo: message))
            }
        }
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        Utils.logFirebaseEvent(eventName: "did_recive_notification")
        if #available(iOS 14.0, *) {
            let presentationOptions: UNNotificationPresentationOptions = [.sound, .badge, .list, .banner]
            completionHandler(presentationOptions)
        } else {
            let presentationOptions: UNNotificationPresentationOptions = [.sound, .badge]
            completionHandler(presentationOptions)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
//        if let postData = userInfo["post_id"] as? String, let userID = userInfo["user_id"] as? String {
//            Constants.isFromCustomURL = true
//            print("Received post_id:", postData)
//            let post = ["user_id": userID, "post_id": postData]
//            NotificationCenter.default.post(Notification(name: Notification.Name("deep_link"),userInfo: post))
//        }
        completionHandler(.newData)
    }
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "")")
        Constants.fcmToken = fcmToken ?? ""
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      print("APNs token retrieved: \(deviceToken)")
       Messaging.messaging().apnsToken = deviceToken
    }
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
}
extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}
