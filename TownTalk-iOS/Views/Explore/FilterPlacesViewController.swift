//
//  FilterPlacesViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 10/06/2023.
//

import UIKit

protocol FilterPlacesViewControllerDelegate{
    func applyFilters(filter: Filters)
}

class FilterPlacesViewController: UIViewController {

    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var lblMostCheckin: UILabel!
    @IBOutlet weak var mostCheckInView: UIView!
    @IBOutlet weak var lblRadius: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var mostTageedView: UIView!
    @IBOutlet weak var lblMostTagged: UILabel!
    
    var delegate: FilterPlacesViewControllerDelegate?
    var mostTagged = false
    var mostCheckin = false
    var filter = Filters(mostCheckin: false, mostTagged: false, radius: 0.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logPageView()
        
        radiusSlider.value = Constants.filter.radius
        mostTagged = Constants.filter.mostTagged
        mostCheckin = Constants.filter.mostCheckin
        if !mostCheckin{
            mostCheckInView.backgroundColor = UIColor.categoryColor
            lblMostCheckin.textColor = UIColor.labelColor
        }else{
            mostCheckInView.backgroundColor = UIColor.appColor
            lblMostCheckin.textColor = UIColor.white
        }
        if !mostTagged{
            mostTageedView.backgroundColor = UIColor.categoryColor
            lblMostTagged.textColor = UIColor.labelColor
        }else{
            mostTageedView.backgroundColor = UIColor.appColor
            lblMostTagged.textColor = UIColor.white
        }
        radiusSlider.minimumValue = 0
        radiusSlider.maximumValue = 30
        lblRadius.text = "\(String(Int(radiusSlider.value))) miles"
        mainView.cornerRadius = 35
        mainView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        self.blurView.addGestureRecognizer(tap)
    }
    @objc func dismissView(){
//        self.dismiss(animated: true)
    }
    @IBAction func sliderValueDidChange(_ sender: Any) {
        lblRadius.text = "\(String(Int(radiusSlider.value))) miles"
        Constants.filter.radius = radiusSlider.value
    }
    @IBAction func applyFiltersPressed(_ sender: Any) {
        self.dismiss(animated: true) {
            self.delegate?.applyFilters(filter: Constants.filter)
        }
    }
    @IBAction func removeFiltersPressed(_ sender: Any) {
        mostCheckin = false
        mostTagged = false
        mostTageedView.backgroundColor = UIColor.categoryColor
        lblMostTagged.textColor = UIColor.labelColor
        mostCheckInView.backgroundColor = UIColor.categoryColor
        lblMostCheckin.textColor = UIColor.labelColor
        radiusSlider.value = 0
        radiusSlider.minimumValue = 0
        radiusSlider.maximumValue = 30
        lblRadius.text = "\(String(Int(radiusSlider.value))) miles"
        Constants.filter = Filters(mostCheckin: false, mostTagged: false, radius: 0.0)
    }
    @IBAction func mostCheckInPressed(_ sender: Any) {
        mostCheckin = !mostCheckin
        Constants.filter.mostCheckin = mostCheckin
        if !mostCheckin{
            mostCheckInView.backgroundColor = UIColor.categoryColor
            lblMostCheckin.textColor = UIColor.labelColor
        }else{
            mostCheckInView.backgroundColor = UIColor.appColor
            lblMostCheckin.textColor = UIColor.white
        }
        
    }
    @IBAction func mostTaggedPfressed(_ sender: Any) {
        mostTagged = !mostTagged
        Constants.filter.mostTagged = mostTagged
        if !mostTagged{
            mostTageedView.backgroundColor = UIColor.categoryColor
            lblMostTagged.textColor = UIColor.labelColor
        }else{
            mostTageedView.backgroundColor = UIColor.appColor
            lblMostTagged.textColor = UIColor.white
        }
    }
}

struct Filters{
    var mostCheckin: Bool = false
    var mostTagged: Bool = false
    var radius: Float = 0.0
    
    init(mostCheckin: Bool, mostTagged: Bool, radius: Float) {
        self.mostCheckin = mostCheckin
        self.mostTagged = mostTagged
        self.radius = radius
    }
}
