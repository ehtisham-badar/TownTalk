//
//  SwitchAccountViewController.swift
//  TownTalk-iOS
//
//  Created by Veripark on 08/09/2023.
//

import UIKit
import Firebase
import FirebaseFunctions


class SwitchAccountViewController: BaseViewController {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var accountTableView: UITableView!
    var accountsList:[UserObjectSP] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIViews()
        setUpConfiguration()
    }
    
    func setupUIViews(){
        mainView.roundCorners(corners: [.topLeft, .topRight], radius: 20.0)
        accountTableView.delegate = self
        accountTableView.dataSource = self
    }
    
    
    func setUpConfiguration(){
       // accountsList = Utils.getAccountsWhoInLoggedin()
        accountsList.append(UserObjectSP(user_id: "0x600001315bd0", username: "TestUser", email: "TestUserJohn@demo.com", userImage: "", normal: false, gmail: false, facebook: false, apple: false))
        accountsList.append(UserObjectSP(user_id: "0x600001314f00", username: "TestUser", email: "TestUserMicheal@gmail.com", userImage: "", normal: false, gmail: false, facebook: false, apple: false))
        accountsList.append(UserObjectSP(user_id: "Aw7VQYQSk7SIY6aTCPg64Yu", username: "TestUser", email: "TestUserRoot@yahoo.com", userImage: "", normal: false, gmail: false, facebook: false, apple: false))
        
        
        accountTableView.reloadData()
    }
    
    
    
    
    

}



extension SwitchAccountViewController : UITableViewDelegate , UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accountsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserAccountCell", for: indexPath) as! UserAccountCell
        cell.username.text = accountsList[indexPath.row].email
        cell.udid.text = "UDID: \(accountsList[indexPath.row].user_id)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.requestNewToken(for: accountsList[indexPath.row].user_id) { token, error in
            if let userToken = token {
                self.switchAccount(with:userToken)
            }
        }
    }
    
    
    
    
    
    
  //   Function to request a new JWT token for a user ID
    func requestNewToken(for userId: String, completion: @escaping (String?, Error?) -> Void) {
        let functions = Functions.functions()

        functions.httpsCallable("generateCustomAuthToken").call(["userId": userId]) { (result, error) in
            if let error = error {
                completion(nil, error)
            } else if let token = (result?.data as? [String: Any])?["token"] as? String {
                completion(token, nil)
            } else {
                completion(nil, NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil))
            }
        }
    }
    
    
    
    
    
    

    // Function to switch accounts using a new token
    func switchAccount(with userId: String) {
        requestNewToken(for: userId) { (token, error) in
            if let token = token {
                // Sign in with the new token
                Auth.auth().signIn(withCustomToken: token) { (authResult, error) in
                    if let error = error {
                        print("Error switching account: \(error.localizedDescription)")
                        // Handle the error
                    } else {
                        // Successfully switched to the new account
                        // Update the UI with the new user's data
                        
                      debugPrint("Currunt User : \(Auth.auth().currentUser?.email)")
                        
                    }
                }
            } else if let error = error {
                print("Error requesting token: \(error.localizedDescription)")
                // Handle the error
            }
        }
    }

    
    
    
    
}
