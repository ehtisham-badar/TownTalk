//
//  Feed.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 05/05/2023.
//

import Foundation

struct Feed : Codable{
    var feed_name: String = ""
    var users: [User]? = nil
    var id: Int? = nil
    
    init(feed_name: String, id: Int? = nil, users: [User]? = nil) {
        self.feed_name = feed_name
        self.id = id
        self.users = users
    }
}

class Location: Codable{
    var name: String = DefaultValue.string
    var main_text: String = DefaultValue.string
    var secondary_text: String = DefaultValue.string
    var placeID: String = DefaultValue.string
    var isSaved: Bool = false
    var houseNo = DefaultValue.string
    var street = DefaultValue.string
    var city = DefaultValue.string
    var state = DefaultValue.string
    var country = DefaultValue.string
    var zip = DefaultValue.string
    var floor = DefaultValue.string
    var address_line1 = DefaultValue.string
    var formattedAddress = DefaultValue.string
    
    var lat: Double = 0
    var lng: Double = 0
    
    init() {
        
    }
    
    init(name: String, main_text: String, secondary_text: String, address: Address? = nil,issaved:Bool,placeId: String) {
        
        self.name = name
        self.main_text = main_text
        self.secondary_text = secondary_text
        self.isSaved = issaved
        self.placeID = placeId
        mapAddressValue(address: address)
    }
    
    func mapAddressValue(address: Address? = nil){
        if let address = address {
            placeID = "\(address.addressID)"
            houseNo = address.houseNo
            city = address.city
            street = address.street
            state = address.state
            country = address.country
            zip = address.zip
            floor = address.apartmentNumber
            lat = address.latitude
            lng = address.longitude
            address_line1 = address.address_line1
        }
    }
}

class Address:NSObject,NSCoding {
    
    var street: String = DefaultValue.string
    var city: String = DefaultValue.string
    var zip: String = DefaultValue.string
    var state: String = DefaultValue.string
    var address_line1: String = DefaultValue.string
    var address_line2: String = DefaultValue.string
    var country: String = DefaultValue.string
    var deliveryNotes: String = DefaultValue.string
    var latitude: Double = 0
    var longitude : Double = 0
    var floor: String = DefaultValue.string
    var apartmentNumber : String = DefaultValue.string
    var addressID: Int = DefaultValue.int
    var addressLabel: String = DefaultValue.string
    var isDefault: Bool = DefaultValue.bool
    var houseNo: String = DefaultValue.string
    
    init(_ productJSonObject: Dictionary<String, Any>?) {
        super.init()
        if(productJSonObject != nil){
            parseJsonData(productJSonObject: productJSonObject!)
        }
        
    }
    
    init(street: String, city: String, zip: String, state: String, address_line1: String, address_line2: String, country: String, deliveryNotes: String, latitude: Double, longitude: Double, floor: String, apartmentNumber: String, addressLabel: String, addressID: Int, isDefault: Bool, houseNo : String ) {
        self.street = street
        self.city = city
        self.zip = zip
        self.state = state
        self.address_line1 = address_line1
        self.address_line2 = address_line2
        self.country = country
        self.deliveryNotes = deliveryNotes
        self.latitude = latitude
        self.longitude = longitude
        self.floor = floor
        self.apartmentNumber = apartmentNumber
        self.addressID = addressID
        self.addressLabel = addressLabel
        self.isDefault = isDefault
        self.houseNo = houseNo
    }
    
    required init(coder decoder: NSCoder) {
        street = decoder.decodeObject(forKey: APIKey.route) as? String ?? DefaultValue.string
        apartmentNumber = decoder.decodeObject(forKey: APIKey.apartmentNumber) as? String ?? DefaultValue.string
        city = decoder.decodeObject(forKey: APIKey.city) as? String ?? DefaultValue.string
        zip = decoder.decodeObject(forKey: APIKey.zip) as? String ?? DefaultValue.string
        state = decoder.decodeObject(forKey: APIKey.state) as? String ?? DefaultValue.string
        address_line1 = decoder.decodeObject(forKey: APIKey.address_line1) as? String ?? DefaultValue.string
        address_line2 = decoder.decodeObject(forKey: APIKey.address_line2) as? String ?? DefaultValue.string
        country = decoder.decodeObject(forKey: APIKey.country) as? String ?? DefaultValue.string
        floor = decoder.decodeObject(forKey: APIKey.floor) as? String ?? DefaultValue.string
        deliveryNotes = decoder.decodeObject(forKey: APIKey.notes) as? String ?? DefaultValue.string
        latitude = decoder.decodeDouble(forKey: APIKey.latitude)
        longitude = decoder.decodeDouble(forKey: APIKey.longitude)
        addressID = decoder.decodeInteger(forKey: APIKey.orderId)
        addressLabel = decoder.decodeObject(forKey: APIKey.addressLabel) as? String ?? DefaultValue.string
        isDefault = decoder.decodeBool(forKey: APIKey.isDefaultAddress) as? Bool ?? DefaultValue.bool
        houseNo = decoder.decodeObject(forKey: APIKey.houseNo) as? String ?? DefaultValue.string
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(street, forKey: APIKey.route)
        coder.encode(apartmentNumber, forKey: APIKey.apartmentNumber)
        coder.encode(city, forKey: APIKey.city)
        coder.encode(zip, forKey: APIKey.zip)
        coder.encode(state, forKey: APIKey.state)
        coder.encode(address_line1, forKey: APIKey.address_line1)
        coder.encode(address_line2, forKey: APIKey.address_line2)
        coder.encode(floor, forKey: APIKey.floor)
        coder.encode(country, forKey: APIKey.country)
        coder.encode(latitude, forKey: APIKey.latitude)
        coder.encode(longitude, forKey: APIKey.longitude)
        coder.encode(addressID, forKey: APIKey.addressID)
        coder.encode(addressLabel, forKey: APIKey.addressLabel)
        coder.encode(isDefault, forKey: APIKey.isDefaultAddress)
        coder.encode(deliveryNotes, forKey: APIKey.notes)
        coder.encode(houseNo, forKey: APIKey.houseNo)
    }
    
    func parseJsonData(productJSonObject: Dictionary<String, Any>) {
        street = productJSonObject[APIKey.route] as? String ?? DefaultValue.string
        apartmentNumber = productJSonObject[APIKey.apartmentNumber] as? String ?? DefaultValue.string
        city = productJSonObject[APIKey.city] as? String ?? DefaultValue.string
        zip = productJSonObject[APIKey.zip] as? String ?? DefaultValue.string
        state = productJSonObject[APIKey.state] as? String ?? DefaultValue.string
        address_line1 = productJSonObject[APIKey.address_line1] as? String ?? DefaultValue.string
        address_line2 = productJSonObject[APIKey.address_line2] as? String ?? DefaultValue.string
        country = productJSonObject[APIKey.country] as? String ?? DefaultValue.string
        floor = productJSonObject[APIKey.floor] as? String ?? DefaultValue.string
        latitude = productJSonObject[APIKey.latitude] as? Double ?? 0
        longitude = productJSonObject[APIKey.longitude] as? Double ?? 0
        addressID = productJSonObject[APIKey.addressID] as? Int ?? DefaultValue.int
        addressLabel = productJSonObject[APIKey.addressLabel] as? String ?? DefaultValue.string
        deliveryNotes = productJSonObject[APIKey.notes] as? String ?? DefaultValue.string
        isDefault = productJSonObject[APIKey.isDefaultAddress] as? Bool ?? DefaultValue.bool
        houseNo = productJSonObject[APIKey.houseNo] as? String ?? DefaultValue.string
    }
    
}
enum APIKey{
    //routecab
    static let rides = "rides"
    static let ride = "ride"
    static let booking = "booking"
    static let createdAt = "created_at"
    static let updatedAt = "updated_at"
    static let deletedAt = "deleted_at"
    static let first_login = "first_login"
    static let wallet = "wallet"
    static let appUrl = "app_url"
    static let appSettings = "app_settings"
    static let partner_app_url = "partner_app_url"
    static let pending_review = "pending_review"
    static let booking_id = "booking_id"
    static let pending_reviews = "pending_reviews"
    static let account_details = "account_details"
    static let jazz_cash_number = "jazz_cash_number"
    static let easy_paisa_number = "easy_paisa_number"
    static let bank_name = "bank_name"
    static let account_title = "account_title"
    static let bank_account_number = "bank_account_number"
    static let faq_url = "faq_url"
    
    static let userId = "users_id"
    static let unread_messages_count = "unread_messages_count"
    static let number = "number"
    static let otp = "otp"
    static let deviceToken = "device_token"
    static let token = "token"
    static let homeLocation = "home_location"
    static let workLocation = "work_location"
    static let email_verified = "email_verified"
    //app settings
    static let key = "key"
    static let value = "value"
    static let MESSAGE = "message"
    static let versionNumber = "version_number"
    static let newUser = "user"
    static let longitude = "longitude"
    static let latitude = "latitude"
    static let authToken = "token"
    static let profile = "profile"
    static let phoneNumber = "phone_number"
    static let firstName = "first_name"
    static let rating = "ratings"
    static let lastName = "last_name"
    static var dateOfBirth = "date_of_birth"
    static var gender = "gender"
    static let imgUrl = "avatar"
    static let email = "email"
    static var addressID = "id"
    static let street = "street"
    static let route = "route"
    static let houseNo = "house_building_no"
    static let apartmentNumber = "apart_no"
    static let city = "city"
    static let zip = "zip"
    static let state = "state"
    static let address_line1 = "address_line1"
    static let address_line2 = "address_line2"
    static let area = "area"
    static let floor = "floor"
    static let placeId = "placeId"
    static let addressLabel = "place_label"
    static let isDefaultAddress = "is_default"
    static let addressDic = "address_dictionary"
    static let totalCount = "total_count"
    static let priceRangeMin = "price_range_min"
    static let priceRangeMax = "price_range_max"
    static let isOnlinePayment = "is_online_payment"
    static let isFreeDelivery = "is_free_delivery"
    static let disclaimerNote = "disclaimer_note"
    static let id = "id"
    static let orderId = "order_id"
    static let notes = "notes"
    static let status =  "status"
    static let cancel_fee = "cancel_fee"
    static let skip = "skip"
    static let paymentMethod = "payment_method"
    static let country = "country"
    static let per_page = "per_page"
    //BOOK RIDE
    static let date_time = "date_time"
    static let gender_preference = "gender_preference"
    static let from_lat = "from_lat"
    static let from_lng = "from_lng"
    static let where_lat = "where_lat"
    static let where_lng = "where_lng"
    static let from_address = "from_address"
    static let to_address = "to_address"
    static let ride_status = "ride_status"
    static let seats = "seats"
    static let payment_method = "payment_method"
    static let driver_id = "driver_id"
    static let passenger_id = "passenger_id"
    static let voucher_code = "voucher_code"
    static let created_ride_id = "created_ride_id"
    static let user_id = "user_id"
    static let isDateSearch = "is_date_search"
    static let totalKms = "total_kms"
    static let completed = "completed"
    static let created_at = "created_at"
    static let updated_at = "updated_at"
    static let deleted_at = "deleted_at"
    static let inprogress = "inprogress"
    static let expired = "expired"
    static let full_name = "full_name"
    static let role_id = "role_id"
    static let message = "message"
    static let audio_file = "audio_file"
    static let read_status = "read_status"
    static let is_audio = "is_audio"
    //payment
    static let base_fair = "base_fair"
    static let d_wallet = "d_wallet"
    static let total_amount = "total_amount"
    static let total_driven_km_cost = "total_driven_km_cost"
    static let total_minutes_cost = "total_minutes_cost"
    static let total_passenger = "total_passenger"
    
    static let driver = "driver"
    static let vehicle = "vehicle"
    static let payment = "payment"
    
    static let name = "name"
    static let model = "model"
    static let registration_no = "registration_no"
    static let chassee_no = "chassee_no"
    static let car_image = "car_image"
    static let year = "year"
    static let car_categories_id = "car_categories_id"
    
    static let category = "category"
    static let base_fare = "base_fare"
    static let per_minute = "per_minute"
    static let per_km = "per_km"
    static let car_document = "car_document"
    static let cnic_copy = "cnic_copy"
    
    static let license_copy = "license_copy"
    static let routecab_wallet = "routecab_wallet"
    static let verified_driver = "verified_driver"
    static let participant = "participant"
    
}
