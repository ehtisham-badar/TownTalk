//
//  SendRequestViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 26/03/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase

protocol SendRequestViewControllerDelegate{
    func feedUpdated()
    func feedCreated1()
}

class SendRequestViewController: BaseViewController,UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var lblSelected: UILabel!
    
    @IBOutlet weak var searchTF: UITextField!
    
    @IBOutlet weak var createAndUpdateFeedButton: UIButton!
    @IBOutlet weak var createAndUpdateFeedLabel: UILabel!


    
    
    var delegate: SendRequestViewControllerDelegate?
    var feedName = ""
    var users = [User]()
    var searchedUsers = [User]()
    var count = 0
    var currentUser: User?
    var feeds = [Feed]()
    var isFromEdit = false
    var editFeed: Feed?
    
    var oldUserKeys :[String] = []
    var newUserKeys :[String] = []

    
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTF.delegate = self
        Utils.getAllUsers { users in
            self.users = users
            self.tableView.reloadData()
            if self.isFromEdit{
                self.createAndUpdateFeedLabel.text = "Update news feed"
                
                self.users = self.users.map { user in
                    var updatedElement = user
                    
                    if let editFeedusers = self.editFeed?.users {
                        if editFeedusers.contains(where: { $0.uid == user.uid }) {
                            updatedElement.isSelected = true
                            self.oldUserKeys.append(updatedElement.uid ?? "")
                        }
                    }
                    return updatedElement
                }

            }else{
                self.createAndUpdateFeedLabel.text = "Create news feed"
            }
            self.lblSelected.text = "\(self.editFeed?.users?.count ?? 0)/50 Selected"
        }
        getCurrentUser { user in
            print(user)
            self.currentUser = user
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchTF.resignFirstResponder()
    }
    func getCurrentUser(completionHandler: @escaping (User) -> Void) {
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").observeSingleEvent(of: .value){ snapshot in
            guard snapshot.value != nil else { return }
            if let value = snapshot.value as? NSNull {
                print("nil")
                return
            }
            let user = try! FirebaseDecoder().decode(User.self, from: snapshot.value as Any)
            completionHandler(user)
        }
    }
    func filterData(for searchText: String) {
        searchedUsers = users.filter { item in
            let username = item.username ?? ""
            return username.lowercased().contains(searchText)
        }
    }
    
    @IBAction func searchDidChange(_ sender: Any) {
        filterData(for: searchTF.text?.lowercased() ?? "")
        if self.searchedUsers.isEmpty {
            self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No User")
        }else{
            self.TableViewRemoveNoDataLable(tableview: self.tableView)
        }
        self.tableView.reloadData()
    }
    @IBAction func buttonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createButtton(_ sender: Any) {
        if isFromEdit{
            if lblSelected.text == "0/50 Selected"{
                self.alert(title: "Alert", message: "Please Select atleast one user")
            }else{
                updateNewsFeed()
                Utils.logFirebaseEvent(eventName: "edit_news_feed")
            }
        }else{
            if lblSelected.text == "0/50 Selected"{
                self.alert(title: "Alert", message: "Please Select atleast one user")
            }else{
                createNewsFeed()
                Utils.logFirebaseEvent(eventName: "create_news_feed")
            }
            
        }
    }
    func createNewsFeed(){
        self.startLoader()
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        let ref = Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").child("feeds")
        let id = self.currentUser?.feeds?.count ?? 0
        let users = self.users.filter({ user in
            user.isSelected ?? false
        })
        
        for i in users {
            self.newUserKeys.append(i.uid ?? "")
        }
        
        let dict = ["\(id)" : [
            "feed_name" : feedName,
            "id": id,
            "users" : users.map({ user in
                user.dictionary
            })
        ]]
        ref.updateChildValues(dict) { error, ref in
            if error == nil{
                
                NotificationCenter.default.post(Notification(name: Notification.Name("refresh"), object: nil, userInfo: ["feed": Feed(feed_name: self.feedName, id: id, users: users )]))
                self.createFeedCountForUserKeysWithDispatchGroup()
                
             
            }else{
                self.stopLoader()
                print(error?.localizedDescription ?? "")
            }
        }
    }
    
    
    
    func updateNewsFeed(){
        self.startLoader()
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        let ref = Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "").child("feeds")
        let id = self.editFeed?.id ?? 0
        let users = self.users.filter({ user in
            user.isSelected ?? false
        })
        
        for i in users {
            self.newUserKeys.append(i.uid ?? "")
        }

        
        let dict = ["\(id)" : [
            "feed_name" : self.editFeed?.feed_name ?? "",
            "id": id,
            "users" : users.map({ user in
                user.dictionary
            })
        ]]
        ref.updateChildValues(dict) { error, ref in
            if error == nil{
                self.updateFeedCountForUserKeysWithDispatchGroup()
                
                
                
                
            }else{
                self.stopLoader()
                print(error?.localizedDescription ?? "")
            }
        }
    }
}

extension SendRequestViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchTextEmpty ? users.count : searchedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserRequestTableViewCell.self)) as? UserRequestTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.lblName.text = isSearchTextEmpty ? (users[indexPath.row].fullName == "" || users[indexPath.row].fullName == nil ? users[indexPath.row].username: users[indexPath.row].fullName) : searchedUsers[indexPath.row].fullName
        cell.lblUsername.text = isSearchTextEmpty ? "@\(users[indexPath.row].username ?? "")" : "@\(searchedUsers[indexPath.row].username ?? "")"
        cell.selectIcon.isHidden = isSearchTextEmpty ?  !(self.users[indexPath.row].isSelected ?? false) : !(self.searchedUsers[indexPath.row].isSelected ?? false)
        Utils.loadImage(imageView: cell.profileImage, urlString: (isSearchTextEmpty ? users[indexPath.row].profile_pic : searchedUsers[indexPath.row].profile_pic) ?? "" , placeHolder: UIImage(named: "placeholder"))
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isSearchTextEmpty {
            
            var searchedUsersSelection = self.searchedUsers[indexPath.row].isSelected ?? false
            if  searchedUsersSelection {
                self.searchedUsers[indexPath.row].isSelected = false
                var indexOfMainUserList = searchUserFindIndexOnUser(targetUser:  self.searchedUsers[indexPath.row])
                self.users[indexOfMainUserList].isSelected =  false

                
            } else{
                self.searchedUsers[indexPath.row].isSelected = true
                var indexOfMainUserList = searchUserFindIndexOnUser(targetUser:  self.searchedUsers[indexPath.row])
                self.users[indexOfMainUserList].isSelected =  true
            }
            
            
           // self.searchedUsers[indexPath.row].isSelected = !(self.users[indexPath.row].isSelected ?? false)
            
           // var indexOfMainUserList = searchUserFindIndexOnUser(targetUser:  self.searchedUsers[indexPath.row])
           // self.users[indexPath.row].isSelected = !(self.users[indexPath.row].isSelected ?? false)

           // self.users[indexOfMainUserList].isSelected = !(self.users[indexPath.row].isSelected ?? false)
            
//            count = self.searchedUsers.filter({ user in
//                user.isSelected ?? false
//            }).count
            
            count = self.users.filter({ user in
                user.isSelected ?? false
            }).count
            self.lblSelected.text = "\(count)/50 Selected"
            self.tableView.reloadData()
            
            
            
            
            
            
            
            
        } else {
            self.users[indexPath.row].isSelected = !(self.users[indexPath.row].isSelected ?? false)
            count = self.users.filter({ user in
                user.isSelected ?? false
            }).count
            self.lblSelected.text = "\(count)/\(users.count) Selected"
            self.tableView.reloadData()
        }
        
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}



extension SendRequestViewController {
    
    
    func updateFeedCountForUserKeysWithDispatchGroup() {

        debugPrint("qq -- OLD Keys..")
        debugPrint("qq -- \(self.oldUserKeys)")
        debugPrint("qq -- New Keys..")
        debugPrint("qq -- \(self.newUserKeys)")
        
        // Start the API calls by calling makeApiCalls with an initial index of 0
        makeApiCalls(index: 0)
      
    }
    
    
    
    func createFeedCountForUserKeysWithDispatchGroup() {
        makeApiCallsNewSecond(index: 0)
    }

    
    func makeApiCalls(index: Int) {
        guard index < self.oldUserKeys.count else {
            // All API calls are done
            debugPrint("All API calls are complete! OLD .")
            makeApiCallsSecond(index: 0)
            
            return
        }

        let userKey = self.oldUserKeys[index]
        debugPrint("qq -- OLD KEY DispatchGroup Enter \(userKey)")

        Utils.checkUsersHaveFeedCount(userKey: userKey) { feedcount in
            // Handle the response of the API call here
            if let feedCount = feedcount {
                if feedCount != 0 {
                    let count = feedCount - 1
                    Utils.updateUserFeedCount(userKey: userKey, feedCount: count) { status in
                        debugPrint("qq -- OLD KEY DispactGroup Leave -  Key \(userKey):\(status)")
                        // Now, move on to the next item in the loop
                        self.makeApiCalls(index: index + 1)
                      
                    }
                } else {
                    Utils.updateUserFeedCount(userKey: userKey, feedCount: 1) { status in
                        debugPrint("qq -- OLD KEY DispactGroup Leave -  Key \(userKey):\(status)")
                        // Now, move on to the next item in the loop
                        self.makeApiCalls(index: index + 1)
                    }
                }
            }
            else {
                Utils.updateUserFeedCount(userKey: userKey, feedCount: 0) { status in
                    debugPrint("qq -- OLD KEY DispactGroup Leave -  Key \(userKey):\(status)")
                    // Now, move on to the next item in the loop
                    self.makeApiCalls(index: index + 1)
                   
                }
            }

        }
    }


    
    
    
    

    func makeApiCallsSecond(index: Int) {
        guard index < self.newUserKeys.count else {
            // All API calls are done
            debugPrint("All API calls are complete! NEW")
            self.navigateBack()
            return
        }

        let userKey = self.newUserKeys[index]
        debugPrint("qq -- New KEY DispatchGroup Enter \(userKey)")

        Utils.checkUsersHaveFeedCount(userKey: userKey) { feedcount in
            // Handle the response of the API call here
            if let feedCount = feedcount {
                if feedCount >= 0 {
                    var count = feedCount + 1
                    Utils.updateUserFeedCount(userKey: userKey, feedCount: count) { status in
                        debugPrint("qq -- New KEY DispactGroup Leave -  Key \(userKey):\(status)")
                        // Now, move on to the next item in the loop
                        self.makeApiCallsSecond(index: index + 1)
                      
                    }
                } else {
                    Utils.updateUserFeedCount(userKey: userKey, feedCount: 1) { status in
                        debugPrint("qq -- New KEY DispactGroup Leave -  Key \(userKey):\(status)")
                        // Now, move on to the next item in the loop
                        self.makeApiCallsSecond(index: index + 1)
                    }
                }
            }
            else {
                Utils.updateUserFeedCount(userKey: userKey, feedCount: 1) { status in
                    debugPrint("qq -- New KEY DispactGroup Leave -  Key \(userKey):\(status)")
                    // Now, move on to the next item in the loop
                    self.makeApiCallsSecond(index: index + 1)
                   
                }
            }

        }
    }
    
    
    
    
    func makeApiCallsNewSecond(index: Int) {
        guard index < self.newUserKeys.count else {
            // All API calls are done
            debugPrint("All API calls are complete! NEW")
            self.navigateBackFromTab()
            return
        }

        let userKey = self.newUserKeys[index]
        debugPrint("qq -- New KEY DispatchGroup Enter \(userKey)")

        Utils.checkUsersHaveFeedCount(userKey: userKey) { feedcount in
            // Handle the response of the API call here
            if let feedCount = feedcount {
                if feedCount >= 0 {
                    var count = feedCount + 1
                    Utils.updateUserFeedCount(userKey: userKey, feedCount: count) { status in
                        debugPrint("qq -- New KEY DispactGroup Leave -  Key \(userKey):\(status)")
                        // Now, move on to the next item in the loop
                        self.makeApiCallsNewSecond(index: index + 1)
                      
                    }
                } else {
                    Utils.updateUserFeedCount(userKey: userKey, feedCount: 1) { status in
                        debugPrint("qq -- New KEY DispactGroup Leave -  Key \(userKey):\(status)")
                        // Now, move on to the next item in the loop
                        self.makeApiCallsNewSecond(index: index + 1)
                    }
                }
            }
            else {
                Utils.updateUserFeedCount(userKey: userKey, feedCount: 1) { status in
                    debugPrint("qq -- New KEY DispactGroup Leave -  Key \(userKey):\(status)")
                    // Now, move on to the next item in the loop
                    self.makeApiCallsNewSecond(index: index + 1)
                   
                }
            }

        }
    }
    
   
  
    
    func navigateBack(){
        
        for controller in self.navigationController!.viewControllers as Array {
            if controller.isKind(of: TabBarController.self) {
                self.stopLoader()
                self.navigationController!.popToViewController(controller, animated: true)
                self.delegate?.feedUpdated()
                break
            }
        }
        
    }
    
    
    
    func navigateBackFromTab(){
        
        for controller in self.navigationController!.viewControllers as Array {
            
            
            if controller.isKind(of: TabBarController.self) {
                self.stopLoader()
                
//                NotificationCenter.default.post(Notification(name: Notification.Name("refresh"), object: nil, userInfo: ["feed": Feed(feed_name: self.feedName, id: id, users: users )]))
                
                self.navigationController!.popToViewController(controller, animated: true)
                break
            }
        }
    }
    
    
    
    
    func searchUserFindIndexOnUser(targetUser:User) ->Int {
        if let index =  self.users.firstIndex(where: { $0.uid == targetUser.uid}) {
            print("Found at index: \(index)")
            return index
        } else {
            print("User not found in the list")
            return 0

        }
        
    }
    
    
    
    
}
