//
//  ZodiacSignListViewController.swift
//  TownTalk-iOS
//
//  Created by Veripark on 10/09/2023.
//

import UIKit

protocol ZodiacSignDelegate: AnyObject {
    func ZodiacSignPassed(ZodiacSign: ZodiacSignModel)
}





class ZodiacSignListViewController: BaseViewController {
    
    @IBOutlet weak var zodiacSignTableView: UITableView!
    @IBOutlet weak var mainView: UIView!
    weak var delegate: ZodiacSignDelegate?
    var selectedZodiacSign: String = "gemini"





    override func viewDidLoad() {
        super.viewDidLoad()
        zodiacSignTableView.delegate = self
        zodiacSignTableView.dataSource = self
        setupUIViews()
        setZodiacForFirstTime()
    }
    
    
    func setupUIViews(){
        mainView.roundCorners(corners: [.topLeft, .topRight], radius: 20.0)
    }
    
    

}


extension ZodiacSignListViewController : UITableViewDelegate , UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Utils.zodiacSignList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZodiacSignCell", for: indexPath) as! ZodiacSignCell
        cell.zodiacSignTitle.text = Utils.zodiacSignList[indexPath.row].name
        if Utils.zodiacSignList[indexPath.row].isSlected {
            cell.zodiacSignCheck.image = UIImage(systemName: "checkmark.circle.fill")?.imageWithColor(UIColor.blue)
        }else{
            cell.zodiacSignCheck.image = UIImage(systemName: "checkmark.circle")?.imageWithColor(UIColor.gray)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            Utils.zodiacSignList =  Utils.zodiacSignList.map { item in
                var updateditem = item
                updateditem.isSlected = false
                return updateditem
            }
            Utils.zodiacSignList[indexPath.row].isSlected = true
            self.delegate?.ZodiacSignPassed(ZodiacSign:Utils.zodiacSignList[indexPath.row])
        }
    }

    
    
    
    func  setZodiacForFirstTime(){
        Utils.zodiacSignList =  Utils.zodiacSignList.map { item in
            var updateditem = item
            updateditem.isSlected = false
            return updateditem
        }
        
        if let index = Utils.zodiacSignList.firstIndex(where: { $0.image == selectedZodiacSign }) {
            print("Found at index: \(index)")
            Utils.zodiacSignList[index].isSlected = true
        } else {
            print("Not found in the array")
        }
    }


}
