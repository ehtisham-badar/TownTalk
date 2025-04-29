//
//  Constants.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 20/03/2023.
//
import UIKit
import GoogleMaps

//MARK: - Constants

class Constants {
    static let APP_NAME = "Town Talk"
    static let language = "language"
    static let isFromSocialLogin = false
    static let GOOGLE_API_KEY = "AIzaSyBWhSSBKoWXaw142h2cdAtfcuDmxVsuKm0"
    static var currentLocation = ""
    static var currentLatitude = 0.0
    static var currentLongitude = 0.0
    static var users = [User]()
    static var selectedNewsFeed = Feed(feed_name: "News Feed", id: 0, users: [User]())
    static var selectedLocation = CLLocation()
    static var selectedRadius = 5000
    static let ZOOM_LEVEL = 9.0
    static var postLocation = PostLocation(city_name: "", state_name: "", latitude: 0.0, longitude: 0.0)
    static var reports = [Report]()
    static var blockedUsers = [User]()
    static var isFromCustomURL = false
    static var filter = Filters(mostCheckin: false, mostTagged: false, radius: 0.0)
    static var fcmToken = ""
    static var serverKey = "AAAAnoVCpBE:APA91bEoLGqXlWutst9k5HveZJ3ISd6vxoylGu5yspTtQQfAeyyjZOe2Jey6C1pVw3I1Wk7b96NqOIjk7J0y1VnJH2UbzlgFmWIbA__RVqtuCajtXK3I1CVek0x0Bfnug5n9aJ3RmgSL"
    static var messageid = ""
}
class FirebaseKeys{
    static let postTable = "posts"
    static let userTable = "users"
    static let businessTable = "business"
    static let profilePhtosStorage = "profile_photos"
    static let postImages = "post_images"
}

//MARK: - Storyboards Calling Helper Class

class Storyboard{
    static let main = "Main"
}

//MARK: - Notification Calling Identifiers

enum NOTIFICATION_NAME{
    static let test = "test"
    static let APPENTERFOREGROUND = "appEnterForeground"
}

//MARK: - App Strings

enum AppStrings{
}

//MARK: - Default Values

enum DefaultValue{
    static let string = ""
    static let float: Float = 0.0
    static let double:Double = 0.0
    static let bool: Bool = false
    static let int: Int = 0
    static let space = " "
    static let comma = ", "
    static let date : Date = Date()
    static let dateFormat = "EEEE dd / yyyy"
    static let defaultDateFormat = "yyyy-MM-dd"
}

//MARK: - Message Strings

enum MessageString: String{
    case defaultString = "Unknown error"
}
