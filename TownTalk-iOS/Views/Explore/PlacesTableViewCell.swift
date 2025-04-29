//
//  PlacesTableViewCell.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/03/2023.
//

import UIKit
import FirebaseDatabase

protocol PlacesTableViewCellDelegate{
    func seeallpressed()
    func openDetail(index: Int)
}

class PlacesTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var checkins = [CheckIn]()
    var towns = [Town]()
    var delegate: PlacesTableViewCellDelegate?
    var places = [ShoppingPlace]()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: String(describing: PalceCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: PalceCollectionViewCell.self))
        collectionView.reloadData()
    }
    @IBAction func seeAllButtonPressed(_ sender: Any) {
        delegate?.seeallpressed()
    }
}

extension PlacesTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(5,self.checkins.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PalceCollectionViewCell.self), for: indexPath) as? PalceCollectionViewCell else { return UICollectionViewCell() }
        cell.setCell(data: checkins[indexPath.item])
        cell.hotspotView.isHidden = true
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 50, height: 350)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.openDetail(index: indexPath.item)
    }
    
    func setCheckInPoint(index: Int){
        let checkedInPlace = self.places[index].address.components(separatedBy: ",")
        let place = checkedInPlace.last?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var flag = true
        
        for index in 0..<self.towns.count {
            print("db = \(self.towns[index].name ?? "")")
            print("\(place ?? "")")
            if self.towns[index].name == place {
                self.towns[index].noOfCheckIns = (self.towns[index].noOfCheckIns ?? 0) + 1
                Database.database().reference().child("towns").setValue(self.towns.map({ town in
                    town.dictionary
                })) { error, ref in
                    
                }
                flag = false
                break
            }
        }
        
        if(flag){
            let town = Town(name: place, noOfCheckIns: 1, lat: self.places[index].lat, lng: self.places[index].lng)
            if town.name != "" && town.lat != 0.0 && town.lng != 0.0 {
                Utils.addTown(town)
                self.towns.append(town)
            }
        }
    }
}
