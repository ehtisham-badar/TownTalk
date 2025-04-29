//
//  Login.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//

import Foundation

extension UserDefaults{
    
    class var language: String? {
        get {
            let language = UserDefaults.standard.string(forKey: Constants.language)
            return language ?? nil
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.language)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var accessToken: String? {
        get {
            let language = UserDefaults.standard.string(forKey: UserDefaultsKey.accessToken)
            return language ?? nil
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.accessToken)
            UserDefaults.standard.synchronize()
        }
    }
    class var accessTokenDoctor: String? {
        get {
            let language = UserDefaults.standard.string(forKey: UserDefaultsKey.accessTokenDoctor)
            return language ?? nil
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.accessTokenDoctor)
            UserDefaults.standard.synchronize()
        }
    }
    class var speciality: Int? {
        get {
            let speciality = UserDefaults.standard.integer(forKey: UserDefaultsKey.speciality)
            return speciality
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.speciality)
            UserDefaults.standard.synchronize()
        }
    }

    class var userId: Int? {
        get {
            let userId = UserDefaults.standard.integer(forKey: UserDefaultsKey.id)
            return userId
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.id)
            UserDefaults.standard.synchronize()
        }
    }
    class var promo: String? {
        get {
            let promoCode = UserDefaults.standard.string(forKey: UserDefaultsKey.promo)
            return promoCode
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.promo)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var loyaltyPoints: Int? {
        get {
            let points = UserDefaults.standard.integer(forKey: UserDefaultsKey.points)
            return points
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.points)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var username: String? {
        get {
            let username = UserDefaults.standard.string(forKey: UserDefaultsKey.username)
            return username
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.username)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var familyUsername: String? {
        get {
            let speciality = UserDefaults.standard.string(forKey: UserDefaultsKey.familyUsername)
            return speciality
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.familyUsername)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var doctorLogin: Bool? {
        get {
            let doctorLogin = UserDefaults.standard.bool(forKey: UserDefaultsKey.doctorLogin)
            return doctorLogin
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.doctorLogin)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var patientLogin: Bool? {
        get {
            let patientLogin = UserDefaults.standard.bool(forKey: UserDefaultsKey.patientLogin)
            return patientLogin
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.patientLogin)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var isMemberProfile: Bool? {
        get {
            let profile = UserDefaults.standard.bool(forKey: UserDefaultsKey.isMemberProfile)
            return profile
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.isMemberProfile)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var isLogout: Bool? {
        get {
            let isLogout = UserDefaults.standard.bool(forKey: UserDefaultsKey.isLogout)
            return isLogout
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.isLogout)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var faceIdEnable: Bool? {
        get {
            let speciality = UserDefaults.standard.bool(forKey: UserDefaultsKey.faceIdEnable)
            return speciality
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.faceIdEnable)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var fingerPrintEnableEnable: Bool? {
        get {
            let speciality = UserDefaults.standard.bool(forKey: UserDefaultsKey.fingerPrintEnableEnable)
            return speciality
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.fingerPrintEnableEnable)
            UserDefaults.standard.synchronize()
        }
    }
        
    //DOCTOR
    
    class var isLogoutDoctor: Bool? {
        get {
            let isLogout = UserDefaults.standard.bool(forKey: UserDefaultsKey.isLogout)
            return isLogout
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.isLogout)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var faceIdEnableDoctor: Bool? {
        get {
            let speciality = UserDefaults.standard.bool(forKey: UserDefaultsKey.faceIdEnable)
            return speciality
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.faceIdEnable)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var fingerPrintEnableEnableDoctor: Bool? {
        get {
            let speciality = UserDefaults.standard.bool(forKey: UserDefaultsKey.fingerPrintEnableEnable)
            return speciality
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.fingerPrintEnableEnable)
            UserDefaults.standard.synchronize()
        }
    }
}

enum UserDefaultsKey{
    static let id = "id"
    static let promo = "promo"
    static let points = "points"
    static let username = "username"
    static let familyUsername = "familyUsername"
    static let user = "user"
    static let accessToken = "access_token"
    static let accessTokenDoctor = "access_token"
    static let speciality = "speciality"
    static var patientLogin = "patientLogin"
    static var doctorLogin = "doctorLogin"
    static var isLogout = "isLogout"
    static var isMemberProfile = "isMemberProfile"
    static var faceIdEnable = "faceIdEnable"
    static var fingerPrintEnableEnable = "fingerPrintEnableEnable"
}

