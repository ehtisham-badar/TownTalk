//
//  SendLocationTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 21/05/2023.
//

import UIKit
import GoogleMaps
import CoreLocation

class SendLocationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mapVire: GMSMapView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var reactionView: UIView!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblLocationTime: UILabel!
    @IBOutlet weak var timeView: UIView!
    
    var location: CurrentLocation?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        mapVire.settings.setAllGesturesEnabled(false)
        mapVire.isUserInteractionEnabled = false
    }
    func locationManagerFunction(){
        let location = CLLocationCoordinate2D(latitude: self.location?.latitude ?? 0.0, longitude: self.location?.longitude ?? 0.0)
        let camera = GMSCameraPosition.camera(withTarget: location, zoom: 12)
        mapVire.animate(to: camera)
        
        // Add marker to current location
        let marker = GMSMarker(position: location)
        marker.map = mapVire
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
