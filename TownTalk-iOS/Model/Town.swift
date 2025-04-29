//
//  Town.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 05/06/2023.
//

import Foundation

struct Town: Codable{
    var name: String? = nil
    var noOfCheckIns: Int? = nil
    var lat: Double? = nil
    var lng: Double? = nil
    
    init(name: String? = nil, noOfCheckIns: Int? = nil, lat: Double? = nil, lng: Double? = nil) {
        self.name = name
        self.noOfCheckIns = noOfCheckIns
        self.lat = lat
        self.lng = lng
    }
}
