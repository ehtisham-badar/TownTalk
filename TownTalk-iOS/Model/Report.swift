//
//  Report.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 31/05/2023.
//

import Foundation

struct Report: Codable{
    var post: Post? = nil
    var report_by_user: User? = nil
    var report_date_time: String? = nil
    var report_text: String? = nil
    
    init(post: Post? = nil, report_by_user: User? = nil, report_date_time: String? = nil,report_text: String? = nil) {
        self.post = post
        self.report_by_user = report_by_user
        self.report_date_time = report_date_time
        self.report_text = report_text
    }
}
