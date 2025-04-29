//
//  Post.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 01/04/2023.
//

import Foundation

struct Post: Codable {
    var user_id: String = ""
    var post_id: String = ""
    var creation_date_time: String = ""
    var image_urls: [String]? = nil
    var video_urls: [String]? = nil
    var video_urls_thumbnails: [String]? = nil
    var post_text: String = ""
    var tagged_business: Business? = nil
    var user: User? = nil
    var like_count: Int? = 0
    var comment_count: Int? = 0
    var dislike_count: Int? = 0
    var post_likes: [PostLikes]? = nil
    var post_dislikes: [PostDisLikes]? = nil
    var comments: [Comment]? = nil
    var post_location: String? = nil
    var post_location1: PostLocation? = nil
    var tagged_users: [User]? = nil
    var tagged_users1: [TaggedUsers]? = nil
    var feed_id: Int? = nil
    var share_count: Int? = nil
    
    init(user_id: String,post_id: String? = nil, image_urls: [String],post_text: String,tagged_business: Business? = nil,user: User? = nil,like_count: Int? = nil,dislike_count: Int? = nil,video_urls: [String]? = nil,video_urls_thumbnails: [String]? = nil,feed_id: Int? = nil,tagged_users1: [TaggedUsers]? = nil) {
        self.user_id = user_id
        self.creation_date_time = Utils.getCurrentDateTime()
        self.image_urls = image_urls
        self.post_text = post_text
        self.tagged_business = tagged_business
        self.user = user
        self.like_count = like_count
        self.dislike_count = like_count
        self.post_id = post_id ?? ""
        self.dislike_count = dislike_count
        self.tagged_business = tagged_business
        self.video_urls = video_urls
        self.video_urls_thumbnails = video_urls_thumbnails
        self.post_location1 = PostLocation(city_name: Utils.user?.city ?? Utils.user?.city ?? "", state_name: "", latitude: Utils.user?.cityLat ?? 0.0, longitude: Utils.user?.cityLng ?? 0.0)
        self.feed_id = feed_id
        self.tagged_users1 = tagged_users1
    }
}

struct PostLocation: Codable{
    var city_name: String = ""
    var state_name: String = ""
    var longitude: Double = 0.0
    var latitude: Double = 0.0
    var country_name: String? = nil
    
    init(city_name: String, state_name: String,latitude: Double,longitude: Double,country_name: String? = nil) {
        self.city_name = city_name
        self.state_name = state_name
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct Business : Codable{
    var name: String = ""
    var address: String = ""
    var id: Int = 0
    var place_id: String? = nil
    var lat: Double? = nil
    var lng: Double? = nil
    
    init(name: String, address: String, id: Int, place_id: String? = nil, lat: Double? = nil, lng: Double? = nil) {
        self.name = name
        self.address = address
        self.id = id
        self.place_id = place_id
        self.lat = lat
        self.lng = lng
    }
}

struct PostLikes: Codable{
    var user_id: String = ""
}

struct PostDisLikes: Codable{
    var user_id: String = ""
}

struct Comment: Codable{
    var comment_id: String = ""
    var comment_text: String = ""
    var commentar_name: String = ""
    var commentar_photo: String = ""
    var user_id: String = ""
    var reply_count: Int? = nil
    var replies: [Replies]? = nil
    var like_count: Int? = nil
    var dislike_count: Int? = nil
    var comment_likes_users: [CommentLikes]? = nil
    var comment_dislikes_users: [CommentDisLikes]? = nil
    var creation_date_time: String? = nil
    var tagged_users1: [String]? = nil
    var tagged_users: [User]? = nil
}

struct Replies: Codable{
    var reply_text: String = ""
    var replier_name: String = ""
    var replier_photo: String = ""
    var user_id: String = ""
    var like_count: Int? = nil
    var reply_likes_users: [ReplyLikes]? = nil
}
struct CommentLikes: Codable{
    var user_id: String = ""
}
struct CommentDisLikes: Codable{
    var user_id: String = ""
}
struct TaggedUsers: Codable{
    var user_id: String = ""
}
struct ReplyLikes: Codable{
    var user_id: String = ""
}
