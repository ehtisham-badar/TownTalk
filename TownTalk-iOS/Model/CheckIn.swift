//
//  CheckIn.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 07/06/2023.
//

import Foundation

struct CheckIn: Codable{
    var place_id: String? = nil
    var place_photo: String? = nil
    var is_hottest: Bool? = nil
    var place_name: String? = nil
    var place_address: String? = nil
    var open_now: Bool? = nil
    var close_time: String? = nil
    var phone: String? = nil
    var email: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var posts: [Post]? = nil
    var reviews: [Reviews]? = nil
    var points: Int? = nil
    var checkinTime: String? = nil
    var tagged_points: Int? = nil
    var checked_in_users: [User]? = nil
    var average_review: Double? = nil
    var city: String? = nil
    
    init(place_id: String? = nil, place_photo: String? = nil, is_hottest: Bool? = nil, place_name: String? = nil, place_address: String? = nil, open_now: Bool? = nil, close_time: String? = nil, phone: String? = nil, email: String? = nil, latitude: Double? = nil, longitude: Double? = nil, posts: [Post]? = nil, reviews: [Reviews]? = nil,checkinTime: String? = nil, checked_in_users: [User]? = nil,city: String? = nil,tagged_points: Int? = nil) {
        self.place_id = place_id
        self.place_photo = place_photo
        self.is_hottest = is_hottest
        self.place_name = place_name
        self.place_address = place_address
        self.open_now = open_now
        self.close_time = close_time
        self.phone = phone
        self.email = email
        self.latitude = latitude
        self.longitude = longitude
        self.posts = posts
        self.reviews = reviews
        self.checkinTime = Utils.getCurrentDateTime()
        self.checked_in_users = checked_in_users
        self.city = city
        self.tagged_points = tagged_points
    }
}

struct Reviews: Codable{
    var user_id: String? = nil
    var review_count: Double? = nil
    var review_text: String? = nil
    
    init(user_id: String? = nil, review_count: Double? = nil, review_text: String? = nil) {
        self.user_id = user_id
        self.review_count = review_count
        self.review_text = review_text
    }
}
