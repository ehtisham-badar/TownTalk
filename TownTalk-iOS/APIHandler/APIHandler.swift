//
//  APIHandler.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 09/05/2023.
//

import Foundation
import UIKit
import GoogleMaps

class APIHandler: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate{
    static let shared = APIHandler()
    let printDebugResponses = true
    func getAddressPredictionsWith(searchString: String, lat: String, lng: String, onSuccess: @escaping (_ response: Any) -> Swift.Void, onError: @escaping (_ message: String,_ code: NSInteger, _ response: Any) -> Swift.Void){
        if searchString.count < 3 { return }
        let encodedString = searchString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
//        let currentCountryCode = Locale.current.regionCode ?? "" &components=country:\(currentCountryCode)
        
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?key="+Constants.GOOGLE_API_KEY+"&input="+encodedString+"&types=(cities)"
        print(urlString)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(url: url as URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        self.resumeDataTaskWith1(request: request, onSuccess: onSuccess, onError: onError)
    }
    func getAddressPredictions(searchString: String, lat: String, lng: String, onSuccess: @escaping (_ response: Any) -> Swift.Void, onError: @escaping (_ message: String,_ code: NSInteger, _ response: Any) -> Swift.Void){
        if searchString.count < 3 { return }
        let encodedString = searchString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        var urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?key="+Constants.GOOGLE_API_KEY+"&input="+encodedString
        
        print(urlString)
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(url: url as URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        self.resumeDataTaskWith1(request: request, onSuccess: onSuccess, onError: onError)
    }
    
    func getCurrentStateCode(lat: Double, lng: Double, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let currentLocation = CLLocation(latitude: lat, longitude: lng)
        
        geocoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            if let error = error {
                NSLog("Reverse geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first,
               let stateCode = placemark.administrativeArea {
                // Extract the state code (e.g., "CA" for California)
                completion(stateCode)
            } else {
                completion(nil)
            }
        }
    }
    
    private func resumeDataTaskWith1(request: NSMutableURLRequest,onSuccess: @escaping (_ response: Any) -> Swift.Void, onError: @escaping (_ message: String,_ code: NSInteger, _ response: Any?) -> Swift.Void){
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){ data,response,error in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == HttpStatusCode.serverError.rawValue {
                    print("Status code: (\(httpResponse.statusCode))")
                    onError("Something Went Wrong", ErrorCode.undefinedError.rawValue, nil)
                    return
                }
                if error != nil{
                    onError((error?.localizedDescription)!, (error! as NSError).code, nil)
                    //   self.printFailerAPILogs(requestURL: (request.url?.absoluteString)!, requestParams: request.httpBody!, requestResponse: error as Any)
                    //                     self.printFailerAPILogs(requestURL: (request.url?.absoluteString)!, requestParams: request.httpBody!, requestResponse: error as Any)
                    
                    return
                }
                
                do {
                    let str = String(decoding: data!, as: UTF8.self)
                    print(str)
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                    
                    if let jsonDict = json as? NSDictionary{
                        if let error = jsonDict.object(forKey: "message") as? NSNumber{
                            
                            
                            self.printFailerAPILogs(requestURL: (request.url?.absoluteString)!, requestParams: request.httpBody!, requestResponse: jsonDict as Any)
                            onError("Something Went Wrong",error.intValue, jsonDict)
                            return
                            
                        }
                        
                    }
                    
                    onSuccess(json)
                    if(self.printDebugResponses && request.httpBody != nil){
                        self.printFailerAPILogs(requestURL: (request.url?.absoluteString)!, requestParams: request.httpBody!, requestResponse: json as Any)
                    }
                    
                } catch let error as NSError {
                    onError(error.localizedDescription, error.code, nil)
                    self.printFailerAPILogs(requestURL: (request.url?.absoluteString)!, requestParams: request.httpBody!, requestResponse: error as Any)
                }
            }
            
        }
        task.resume()
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }
    private func printFailerAPILogs(requestURL: String, requestParams: Data, requestResponse: Any){
        
        print("requestURL: \(requestURL)")
        do{
            let params = try JSONSerialization.jsonObject(with: requestParams, options: [])
            print("requestParams: \(String(data: try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted), encoding: .utf8 )!)")
            
        } catch let error as NSError{
            print("requestParams: \(error)")
        }
        print("requestResponse: \(requestResponse)")
    }
}
enum HttpStatusCode: Int {
    case serverError = 500
    case badRequest = 400
    case forbidden = 403
    case success = 200
    case unauthorized = 401
}
enum ErrorCode: Int{
    case undefinedError = 1, deauthenticated, duplicate, doesNotExist,rest_error_code
    case internetError = -1009
}
