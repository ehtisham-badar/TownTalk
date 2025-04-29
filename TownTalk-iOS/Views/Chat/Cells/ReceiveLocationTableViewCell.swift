//
//  ReceiveLocationTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 21/05/2023.
//

import UIKit
import GoogleMaps
import CoreLocation

class ReceiveLocationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var reactionView: UIView!
    @IBOutlet weak var lblLocationTime: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    
    @IBOutlet weak var timeView: UIView!
    var location: CurrentLocation?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        mapView.settings.setAllGesturesEnabled(false)
        mapView.isUserInteractionEnabled = false
    }
    func locationManagerFunction(){
        let location = CLLocationCoordinate2D(latitude: self.location?.latitude ?? 0.0, longitude: self.location?.longitude ?? 0.0)
        let camera = GMSCameraPosition.camera(withTarget: location, zoom: 12)
        mapView.animate(to: camera)
        
        // Add marker to current location
        let marker = GMSMarker(position: location)
        marker.map = mapView
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
