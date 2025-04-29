//
//  Notification.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 01/07/2023.
//

import Foundation

struct AppNotification: Codable{
    var user_id: String? = nil
    var post_id: String? = nil
    var time: String? = nil
    var event: String? = nil
    var is_read: Bool = false
    var notification_id: String? = nil
    var sender_user_id: String? = nil
    
    init(user_id: String? = nil, post_id: String? = nil, event: String? = nil,notification_id: String? = nil, sender_user_id: String? = nil) {
        self.user_id = user_id
        self.post_id = post_id
        self.time = Utils.getCurrentDateTime()
        self.event = event
        self.notification_id = notification_id
        self.sender_user_id = sender_user_id
    }
}

enum EventNotification: String, Codable{
    case like = "like"
    case comment = "comment"
    case tag = "tag"
    case mention = "mention"
    case comment_like = "comment_like"
    case comment_mention = "comment_mention"
    case post_tag = "post_tag"
    case message = "message"
}
