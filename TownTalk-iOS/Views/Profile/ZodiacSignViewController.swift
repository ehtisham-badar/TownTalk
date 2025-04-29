//
//  ZodiacSignViewController.swift
//  TownTalk-iOS
//
//  Created by Veripark on 10/09/2023.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class ZodiacSignViewController: BaseViewController {
    
    
    @IBOutlet weak var loveprogressView: UIProgressView!
    @IBOutlet weak var careerprogressView: UIProgressView!
    @IBOutlet weak var luckprogressView: UIProgressView!
    @IBOutlet weak var familyprogressView: UIProgressView!
    @IBOutlet weak var businessprogressView: UIProgressView!
    @IBOutlet weak var zodiacSignName: UILabel!
    @IBOutlet weak var zodiacSignDescription: UILabel!
    @IBOutlet weak var zodiacSignImageView: UIImageView!
    @IBOutlet weak var currentDate: UILabel!
    @IBOutlet weak var zodiacSignListImageView: UIImageView!
    @IBOutlet weak var backImageView: UIImageView!
    var isCurrentUser : Bool = true
    var otherUserid:String = ""
    var selectedZodiacSign:String = ""
    
    var dummyModel =   ZodiacSignModel(name: "Aries – March 21st – April 19th",
                                          description: "Independent and strong‒willed, you are a force to be reckoned with! You love nothing more than an exciting new goal to tackle, and you do your best work when you’re flying solo. Your passion and energy keep the rest of us on our toes!",
                                          career: 85,
                                          love: 75,
                                          luck: 90,
                                          family: 70,
                                          business: 80,
                                          isSlected: false,
                                          image: "aries")
    
    
    var dummyModel2 = ZodiacSignModel(name: "Not Selected",
                                          description: "Not Selected",
                                          career: 10,
                                          love: 10,
                                          luck: 10,
                                          family: 10,
                                          business: 10,
                                          isSlected: false,
                                          image: "unavailable")
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpProgressView()
        if isCurrentUser {
            zodiacSignListImageView.isHidden = false
            getZodiacSignOfProfile(userId:Auth.auth().currentUser?.uid ?? "" )
        }else{
            zodiacSignListImageView.isHidden = true
            getZodiacSignOfProfile(userId: otherUserid )
        }
    }
    
    
    func setUpProgressView(){
        zodiacSignImageView.layer.cornerRadius = zodiacSignImageView.frame.size.width / 2
        zodiacSignImageView.clipsToBounds = true
        loveprogressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.5) // Adjust the y-scale for the desired height
        careerprogressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.5) // Adjust the y-scale for the desired height
        luckprogressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.5) // Adjust the y-scale for the desired height
        familyprogressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.5) // Adjust the y-scale for the desired height
        businessprogressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.5) // Adjust the y-scale for the desired height
        
        let tapGestureRecognizermsgButton = UITapGestureRecognizer(target: self, action: #selector(listOfZodiacButtonPressed(tapGestureRecognizer:)))
        zodiacSignListImageView.addGestureRecognizer(tapGestureRecognizermsgButton)
        zodiacSignListImageView.isUserInteractionEnabled = true
        
        
        let tapGestureRecognizeraddUserToLoginProfileFeedButton = UITapGestureRecognizer(target: self, action: #selector(backButtonPressed(tapGestureRecognizer:)))
        backImageView.addGestureRecognizer(tapGestureRecognizeraddUserToLoginProfileFeedButton)
        backImageView.isUserInteractionEnabled = true

        
    }
    
    
    @objc func backButtonPressed(tapGestureRecognizer: UITapGestureRecognizer) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func listOfZodiacButtonPressed(tapGestureRecognizer: UITapGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: ZodiacSignListViewController.self)) as! ZodiacSignListViewController
        vc.delegate = self
        vc.selectedZodiacSign = selectedZodiacSign
        self.present(vc, animated: true)
    }

}



extension ZodiacSignViewController : ZodiacSignDelegate {
    
    func ZodiacSignPassed(ZodiacSign: ZodiacSignModel) {
        setZodiacSignUserProfile(userId: Auth.auth().currentUser?.uid ?? "" , zodiacSign: ZodiacSign)
        self.zodiacSignName.text = ZodiacSign.image.uppercased()
        self.zodiacSignDescription.text = ZodiacSign.description
        self.zodiacSignImageView.image = UIImage(named: ZodiacSign.image)
        self.loveprogressView.setProgress(Float(Double(ZodiacSign.love) / 100.0) , animated: false)
        self.careerprogressView.setProgress(Float(Double(ZodiacSign.career) / 100.0) , animated: false)
        self.luckprogressView.setProgress(Float(Double(ZodiacSign.luck) / 100.0) , animated: false)
        self.familyprogressView.setProgress(Float(Double(ZodiacSign.family) / 100.0) , animated: false)
        self.businessprogressView.setProgress(Float(Double(ZodiacSign.business) / 100.0) , animated: false)
    }
    
    func setData(ZodiacSign: ZodiacSignModel){
        self.zodiacSignName.text = ZodiacSign.image.uppercased()
        self.zodiacSignDescription.text = ZodiacSign.description
        self.zodiacSignImageView.image = UIImage(named: ZodiacSign.image)
        self.loveprogressView.setProgress(Float(Double(ZodiacSign.love) / 100.0) , animated: false)
        self.careerprogressView.setProgress(Float(Double(ZodiacSign.career) / 100.0) , animated: false)
        self.luckprogressView.setProgress(Float(Double(ZodiacSign.luck) / 100.0) , animated: false)
        self.familyprogressView.setProgress(Float(Double(ZodiacSign.family) / 100.0) , animated: false)
        self.businessprogressView.setProgress(Float(Double(ZodiacSign.business) / 100.0) , animated: false)
        selectedZodiacSign = ZodiacSign.image
        
    }
    
    
    func getZodiacSignOfProfile(userId:String){
        let ref = Database.database().reference()
        let customKeyName = "ZodiacObject"
        let userObjectRef = ref.child("users").child(userId).child(customKeyName)
        // Check if the custom object key exists
        userObjectRef.observeSingleEvent(of: .value) { (snapshot, error) in
            if let error = error {
                print("Error checking if the custom object key exists: \(error)")
                return
            }
            if snapshot.exists() {
                if let objectData = snapshot.value as? [String: Any] {
                     // Handle the retrieved object data here
                     print("Retrieved Object Data: \(objectData)")
                    
                    if let imageUrl = objectData["image"] as? String {
                        // Use the imageUrl here
                        print("Image URL: \(imageUrl)")
                        self.zodiacSignImageView.image = UIImage(named: imageUrl)
                        self.zodiacSignImageView.contentMode = .scaleAspectFit
                    }
                    
                    guard let image =  objectData["image"] as? String else { return }
                    guard let name =  objectData["name"] as? String else { return }
                    guard let description =  objectData["description"] as? String else { return }
                    guard let career =  objectData["career"] as? Int else { return }
                    guard let love =  objectData["love"] as? Int else {return  }
                    guard let luck =  objectData["luck"] as? Int else { return }
                    guard let family =  objectData["family"] as? Int else {return }
                    guard let business =  objectData["business"] as? Int else { return }
                    
                    var model = ZodiacSignModel(name: name,
                                                description: description,
                                                career: career,
                                                love: love,
                                                luck: luck,
                                                family: family,
                                                business: business,
                                                isSlected: true,
                                                image: image)
                    
                    self.setData(ZodiacSign: model)
                 } else {
                     print("Object data is not available or is in an unexpected format.")
                     self.setData(ZodiacSign: self.dummyModel)

                     
                 }
            } else {
                // The custom object key does not exist
                print("Custom Object Key does not exist")
                self.setData(ZodiacSign: self.dummyModel2)

            }
        }
        
        
        
    }
    
    
    func setZodiacSignUserProfile(userId:String , zodiacSign:ZodiacSignModel){
        let ref = Database.database().reference()
        let userKey = "userKey1"  // Replace with the actual userKey
        let customKeyName = "ZodiacObject"  // Replace with your desired key name
        let userObject: [String: Any] = [
            "name": zodiacSign.name,
            "description": zodiacSign.description,
            "image": zodiacSign.image,
            "family": zodiacSign.family,
            "love": zodiacSign.love,
            "luck": zodiacSign.luck,
            "career": zodiacSign.career,
            "business": zodiacSign.business,
        ]
        let userRef = ref.child("users").child(userId).child(customKeyName)
        userRef.setValue(userObject) { (error, _) in
            if let error = error {
                print("Error adding object with custom key to the user: \(error.localizedDescription)")
                
            } else {
                print("Object with custom key added to the user successfully!")
            }
        }
        
    }
    
    
    
    
}
