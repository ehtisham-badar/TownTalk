//
//  AddUsersViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 13/05/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

protocol AddUsersViewControllerDelegate{
    func updateUserList(users: [User])
}

class AddUsersViewController: BaseViewController,UITextFieldDelegate {
    
    @IBOutlet weak var searchTF: UITextField!
    @IBOutlet weak var lblSelected: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblCreateText: UILabel!
    
    var delegate: AddUsersViewControllerDelegate?
    var groupName: String = ""
    var groupData: Chat?
    var users = [User]()
    var searchedUsers = [User]()
    var count = 0
    var isFromEdit: Bool = false
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startLoader()
        registerNib()
        searchTF.delegate = self
        if isFromEdit{
            lblCreateText.text = "Update Group"
        }
        Utils.getAllUsers { users in
            self.users = users
            for i in 0..<self.users.count{
                if self.users[i].uid == Auth.auth().currentUser?.uid ?? ""{
                    self.users[i].isSelected = true
                    self.users[i].is_admin = true
                }
            }
            self.lblSelected.text = "\(1)/50 Selected"
            self.tableView.reloadData()
            self.stopLoader()
            if self.isFromEdit{
                self.users = self.users.map { user in
                    var updatedElement = user
                    if self.groupData!.group_users!.contains(where: { $0.uid == user.uid }) {
                        updatedElement.isSelected = true
                    }
                    return updatedElement
                }
            }
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchTF.resignFirstResponder()
    }
    func filterData(for searchText: String) {
        searchedUsers = users.filter { item in
            let username = item.username ?? ""
            return username.lowercased().contains(searchText)
        }
    }
    @IBAction func searcDidChange(_ sender: Any) {
        filterData(for: searchTF.text?.lowercased() ?? "")
        if isSearchTextEmpty{
            if self.users.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No User")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
        }else{
            if self.searchedUsers.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No User")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
        }
        self.tableView.reloadData()
    }
    
    func registerNib(){
        tableView.register(UINib(nibName: String(describing: MyChatTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: MyChatTableViewCell.self))
    }
    @IBAction func buttonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createButtton(_ sender: Any) {
        if isFromEdit{
            updateGroup(users: self.users.filter({ user in
                user.isSelected ?? false
            }))
        }else{
            if isSearchTextEmpty{
                if self.users.filter({ user in
                    user.isSelected ?? false
                }).count > 2{
                    createGroup()
                }else{
                    self.alert(title: "Alert", message: "Please Select atleast 3 users")
                }
            }else{
                if self.searchedUsers.filter({ user in
                    user.isSelected ?? false
                }).count > 2{
                    createGroup()
                }else{
                    self.alert(title: "Alert", message: "Please Select atleast 3 users")
                }
            }
        }
        
    }
    func createGroup(){
        self.startLoader()
        let users = self.users.filter({ user in
            user.isSelected ?? false
        })
        
        let group = Chat(user: User(profile_pic: Auth.auth().currentUser?.photoURL?.absoluteString ?? "", username: Auth.auth().currentUser?.displayName ?? "", email: Auth.auth().currentUser?.email ?? "", phone: "", zip_code: ""), time: Utils.getCurrentDateTime(), group_name: groupName,group_users: users,is_group: true)
        Database.database().reference().child("chats").childByAutoId().setValue(group.dictionary) { error, ref in
            if error == nil{
                for controller in self.navigationController!.viewControllers as Array {
                    if controller.isKind(of: TabBarController.self) {
                        self.stopLoader()
                        self.navigationController!.popToViewController(controller, animated: true)
                        break
                    }
                }
            }
            
            Utils.logFirebaseEvent(eventName: "created_group")
        }
    }
    func updateGroup(users: [User]){
        Database.database().reference().child("chats").child(self.groupData?.group_id ?? "").updateChildValues(["group_users": users.map({ user in
            user.dictionary
        })]) { error, ref in
            if error == nil{
                self.delegate?.updateUserList(users: self.users.filter({ user in
                    user.isSelected ?? false
                }))
                self.navigationController?.popViewController(animated: true)
                
            }
        }
    }
}
extension AddUsersViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchTextEmpty ? users.count : searchedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserRequestTableViewCell.self)) as? UserRequestTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.lblName.text = isSearchTextEmpty ? users[indexPath.row].fullName == "" ? users[indexPath.row].username : users[indexPath.row].fullName : searchedUsers[indexPath.row].fullName == "" ? searchedUsers[indexPath.row].username : searchedUsers[indexPath.row].fullName
        cell.lblUsername.text = isSearchTextEmpty ? "@\(users[indexPath.row].username ?? "")" : "@\(searchedUsers[indexPath.row].username ?? "")"
        cell.selectIcon.isHidden = isSearchTextEmpty ?  !(self.users[indexPath.row].isSelected ?? false) : !(self.searchedUsers[indexPath.row].isSelected ?? false)
        Utils.loadImage(imageView: cell.profileImage, urlString: (isSearchTextEmpty ? users[indexPath.row].profile_pic : searchedUsers[indexPath.row].profile_pic) ?? "" , placeHolder: UIImage(named: "placeholder"))
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFromEdit{
            self.groupData?.group_users = self.users
        }
        if isSearchTextEmpty{
            if self.users[indexPath.row].uid == Auth.auth().currentUser?.uid ?? ""{
                return
            }
        }else{
            if self.searchedUsers[indexPath.row].uid == Auth.auth().currentUser?.uid ?? ""{
                return
            }
        }
        if !isSearchTextEmpty{
            self.searchedUsers[indexPath.row].isSelected = !(self.users[indexPath.row].isSelected ?? false)
            count = self.searchedUsers.filter({ user in
                user.isSelected ?? false
            }).count
            self.lblSelected.text = "\(count)/50 Selected"
            self.tableView.reloadData()
        }else{
            self.users[indexPath.row].isSelected = !(self.users[indexPath.row].isSelected ?? false)
            count = self.users.filter({ user in
                user.isSelected ?? false
            }).count
            self.lblSelected.text = "\(count)/50 Selected"
            self.tableView.reloadData()
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchTF.resignFirstResponder()
    }
}
