//
//  NewChatViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 13/05/2023.
//

import UIKit
import FirebaseAuth

class NewChatViewController: BaseViewController,UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTF: UITextField!
    
    var users = [User]()
    var searchedUsers = [User]()
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.getAllUsers { users in
            self.users = users
            if self.searchedUsers.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No User")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
            if let index = self.users.firstIndex(where: {$0.uid == Auth.auth().currentUser?.uid ?? ""}){
                print(index)
                self.users.remove(at: index)
            }
        }
        searchTF.delegate = self
        registerNib()
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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchTF.resignFirstResponder()
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createGroupButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: CreateGroupViewController.self)) as! CreateGroupViewController
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension NewChatViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MyChatTableViewCell.self)) as! MyChatTableViewCell
        cell.selectionStyle = .none
        cell.delegate = self
        cell.button.tag = indexPath.row
        cell.setUserCells(user: searchedUsers[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MessageViewController.self)) as! MessageViewController
        vc.user = searchedUsers[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension NewChatViewController: MyChatTableViewCellDelegate{
    func openUserProfile(index: Int) {
        if Auth.auth().currentUser?.uid ?? "" == (searchedUsers[index].uid){
            self.tabBarController?.selectedIndex = 4
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        vc.fromOtherUserProfile = true
        vc.userID = searchedUsers[index].uid ?? ""
        vc.index = index
        vc.otherUser = searchedUsers[index]
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
