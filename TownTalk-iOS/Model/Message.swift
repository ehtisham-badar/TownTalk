//
//  Message.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 14/05/2023.
//

import Foundation

struct Message: Codable{
    var message: String? = nil
    var sender_id: String? = nil
    var receiver_id: String? = nil
    var message_id: String? = nil
    var time: String? = nil
    var sender_user: User? = nil
    var receiver_user: User? = nil
    var group_chat: Chat? = nil
    var conversation_id: String? = nil
    var last_message: String? = nil
    var image_url: String? = nil
    var video_url: String? = nil
    var location: CurrentLocation? = nil
    var is_request_accepted: Bool? = nil
    var reactions: [String: Int]? = nil
    var is_deleted: Bool? = nil
    
    init(message: String? = nil, sender_id: String? = nil, receiver_id: String? = nil,time: String? = nil,sender_user: User? = nil,receiver_user: User? = nil,image_url: String? = nil,video_url: String? = nil, location: CurrentLocation? = nil, is_request_accepted: Bool? = nil) {
        self.message = message
        self.sender_id = sender_id
        self.receiver_id = receiver_id
        self.time = Utils.getCurrentDateTime()
        self.conversation_id = UUID().uuidString
        self.sender_user = sender_user
        self.receiver_user = receiver_user
        self.image_url = image_url
        self.video_url = video_url
        self.location = location
        self.is_request_accepted = is_request_accepted
    }
}

struct Chat: Codable{
    var messages: [Message]? = nil
    var user: User? = nil
    var chat_id: String? = nil
    var last_message: String? = nil
    var time: String? = nil
    var group_name: String? = nil
    var group_id: String? = nil
    var group_users: [User]? = nil
    var group_image: String? = nil
    var is_group: Bool? = false
    var is_request_accepted: Bool? = nil
}

struct CurrentLocation: Codable{
    var latitude: Double? = nil
    var longitude: Double? = nil
    var address: String? = nil
    var duration: Double? = nil
    var sentTime: Double? = nil
}
