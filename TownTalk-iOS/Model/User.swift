//
//  User.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 28/03/2023.
//

import Foundation

struct User: Codable {
    var uid: String? = ""
    var fullName: String? = nil
    var profile_pic: String? = ""
    var username: String? = ""
    var email: String? = ""
    var phone: String? = ""
    var zip_code: String? = ""
    var feeds: [Feed]? = nil
    var isSelected: Bool? = nil
    var is_admin: Bool? = nil
    var is_blocked: Bool? = nil
    var bio: String? = nil
    var city: String? = nil
    var cityLat: Double? = nil
    var cityLng: Double? = nil
    var checked_in_time: String? = nil
    var is_deleted: Bool? = nil
    var fcm: String? = nil
    
    init(profile_pic: String, username: String, email: String, phone: String, zip_code: String,fullName: String? = nil,feeds: [Feed]? = nil,isSelected: Bool? = nil,bio: String? = nil,city: String? = nil,uid: String? = nil,cityLat: Double? = nil,cityLng: Double? = nil,checked_in_time: String? = nil,is_deleted: Bool? = nil,fcm: String? = nil) {
        self.profile_pic = profile_pic
        self.username = username
        self.email = email
        self.phone = phone
        self.zip_code = zip_code
        self.fullName = fullName
        self.feeds = feeds
        self.isSelected = isSelected
        self.bio = bio
        self.city = city
        self.uid = uid ?? ""
        self.cityLat = cityLat
        self.cityLng = cityLng
        self.checked_in_time = checked_in_time
        self.is_deleted = is_deleted
        self.fcm = fcm
    }
}
