//
//  LocationManager.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 21/05/2023.
//

import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager!
    
    func shareLocation(duration: TimeInterval) {
        // Initialize location manager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        // Request authorization from the user
        locationManager.requestWhenInUseAuthorization()
        
        // Check if location services are enabled
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            
            // Schedule a timer to stop location updates after the specified duration
            Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(stopLocationUpdates), userInfo: nil, repeats: false)
        }
    }
    
    @objc func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates here
        if let location = locations.last {
            // Access the location data
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            // Use the location data as needed
            print("Latitude: \(latitude), Longitude: \(longitude)")
        }
    }
}
