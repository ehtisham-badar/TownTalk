//
//  RequestsViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 24/05/2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase

class RequestsViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTF: UITextField!
    
    var chats = [Chat]()
    var searchedChats = [Chat]()
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNibs()
        searchTF.delegate = self
        fetchChats()
        self.logPageView()
    }
    func fetchChats(){
        self.startLoader()
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).observe(.value) { (snapshot) in
            self.chats.removeAll()
            guard let value = snapshot.value as? [String:Any] else {
                if self.chats.isEmpty{
                    self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Request Found")
                }else{
                    self.TableViewRemoveNoDataLable(tableview: self.tableView)
                }
                self.stopLoader()
                self.tableView.reloadData()
                return
            }
            value.forEach { (key, value2) in
                guard let value1 = value2 as? [String:Any] else {
                    if self.chats.isEmpty{
                        self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Request Found")
                    }else{
                        self.TableViewRemoveNoDataLable(tableview: self.tableView)
                    }
                    self.stopLoader()
                    self.tableView.reloadData()
                    return
                }
                var message1 = try! FirebaseDecoder().decode(Chat.self, from: value1)
                message1.user?.uid = key
                self.chats.append(message1)
            }
            self.chats = self.chats.filter { chat in
                !(chat.is_request_accepted ?? true)
            }
            self.chats = self.chats.sorted(by: { (message1, message2) -> Bool in
                guard let time1 = message1.time, let time2 = message2.time else {
                    return false
                }
                return time1 > time2
            })
            if self.chats.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Request Found")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
            self.stopLoader()
            
            self.tableView.reloadData()
        }
    }
    
    func registerNibs(){
        tableView.register(UINib(nibName: String(describing: MyChatTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: MyChatTableViewCell.self))
    }
    func filterData(for searchText: String) {
        searchedChats = chats.filter { item in
            let username = item.user?.username ?? ""
            return username.lowercased().contains(searchText)
        }
    }
    
    @IBAction func searchValueDidChange(_ sender: Any) {
        filterData(for: searchTF.text?.lowercased() ?? "")
        if isSearchTextEmpty{
            if self.chats.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No User")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
        }else{
            if self.searchedChats.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No User")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
        }
        self.tableView.reloadData()
    }
    @IBAction func backPresse(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension RequestsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchTextEmpty ? chats.count : searchedChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyChatTableViewCell") as? MyChatTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.delegate = self
        cell.button.tag = indexPath.row
        if chats[indexPath.row].is_group ?? false{
            if isSearchTextEmpty{
                cell.lblName.text = chats[indexPath.row].group_name ?? ""
                cell.lblMessage.text = chats[indexPath.row].last_message ?? ""
                Utils.loadImage(imageView: cell.profileImage, urlString: chats[indexPath.row].group_image ?? "", placeHolder: UIImage(named: "placeholder"))
                cell.lblTime.text = Utils.formatTime(inputTime: chats[indexPath.row].time ?? "")
            }else{
                cell.lblName.text = searchedChats[indexPath.row].group_name ?? ""
                cell.lblMessage.text = searchedChats[indexPath.row].last_message ?? ""
                Utils.loadImage(imageView: cell.profileImage, urlString: searchedChats[indexPath.row].group_image ?? "", placeHolder: UIImage(named: "placeholder"))
                cell.lblTime.text = Utils.formatTime(inputTime: searchedChats[indexPath.row].time ?? "")
            }
        }else{
            if isSearchTextEmpty{
                cell.lblName.text = (chats[indexPath.row].user?.fullName == "" || chats[indexPath.row].user?.fullName == nil) ? chats[indexPath.row].user?.username : chats[indexPath.row].user?.fullName
                cell.lblMessage.text = chats[indexPath.row].last_message ?? ""
                Utils.loadImage(imageView: cell.profileImage, urlString: chats[indexPath.row].user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                cell.lblTime.text = Utils.formatTime(inputTime: chats[indexPath.row].time ?? "")
            }else{
                cell.lblName.text = (searchedChats[indexPath.row].user?.fullName == "" || searchedChats[indexPath.row].user?.fullName == nil) ? searchedChats[indexPath.row].user?.username : searchedChats[indexPath.row].user?.fullName
                cell.lblMessage.text = searchedChats[indexPath.row].last_message ?? ""
                Utils.loadImage(imageView: cell.profileImage, urlString: searchedChats[indexPath.row].user?.profile_pic ?? "", placeHolder: UIImage(named: "placeholder"))
                cell.lblTime.text = Utils.formatTime(inputTime: searchedChats[indexPath.row].time ?? "")
            }
        }
       
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MessageViewController.self)) as! MessageViewController
        vc.user = isSearchTextEmpty ? chats[indexPath.row].user : searchedChats[indexPath.row].user
        vc.chat = chats[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension RequestsViewController: MyChatTableViewCellDelegate{
    func openUserProfile(index: Int) {
        if Auth.auth().currentUser?.uid ?? "" == (isSearchTextEmpty ? chats[index].user?.uid ?? "" : searchedChats[index].user?.uid ?? ""){
            self.tabBarController?.selectedIndex = 4
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        vc.fromOtherUserProfile = true
        vc.userID = isSearchTextEmpty ? chats[index].user?.uid ?? "" : searchedChats[index].user?.uid ?? ""
        vc.index = index
        vc.otherUser = isSearchTextEmpty ? chats[index].user : searchedChats[index].user
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
