//
//  MyChatViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase

class MyChatViewController: BaseViewController,UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTF: UITextField!
    @IBOutlet weak var btnRequest: UIButton!
    
    var chats = [Chat]()
    var countchats = [Chat]()
    var searchedChats = [Chat]()
    var isSearchTextEmpty: Bool {
        return searchTF.text?.isEmpty ?? true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchCount()
        searchTF.delegate = self
        setView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchChats()
    }
    
    private func setView(){
        
        registerNibs()
    }
    
    private func registerNibs(){
        tableView.register(UINib(nibName: "MyChatTableViewCell", bundle: nil), forCellReuseIdentifier: "MyChatTableViewCell")
    }
    
    func filterData(for searchText: String) {
        searchedChats = chats.filter { item in
            let username = item.user?.username ?? ""
            return username.lowercased().contains(searchText) ?? false || item.group_name?.lowercased().contains(searchText) ?? false
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchTF.resignFirstResponder()
    }
    @IBAction func requestButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: RequestsViewController.self)) as! RequestsViewController
    
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func fetchCount(){
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).observe(.value) { (snapshot) in
            self.countchats.removeAll()
            guard let value = snapshot.value as? [String:Any] else {
                return
            }
            value.forEach { (key, value2) in
                guard let value1 = value2 as? [String:Any] else {
                    return
                }
                var message1 = try! FirebaseDecoder().decode(Chat.self, from: value1)
                message1.user?.uid = key
                self.countchats.append(message1)
            }
            self.countchats = self.countchats.filter { chat in
                !(chat.is_request_accepted ?? true)
            }
            let count  = self.countchats.filter { chat in
                !(chat.is_request_accepted ?? true)
            }.count
            let title = count > 0 ? "Requests(\(count))" : "Requests"

            // Create an attributed string with underline and blue color attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.blue
            ]
            let attributedTitle = NSAttributedString(string: title, attributes: attributes)

            // Set the attributed title for the button
            self.btnRequest.setAttributedTitle(attributedTitle, for: .normal)
        }
    }
    @IBAction func searchValueDidChange(_ sender: Any) {
        filterData(for: searchTF.text?.lowercased() ?? "")
        if isSearchTextEmpty{
            if self.chats.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Chat Found")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
        }else{
            if self.searchedChats.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Chat Found")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
        }
        self.tableView.reloadData()
    }
    func fetchChats(){
        self.startLoader()
        self.chats.removeAll()
        Database.database().reference().child("chats").child(Auth.auth().currentUser!.uid).observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [String:Any] else {
                if self.chats.isEmpty{
                    self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Chat Found")
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
                        self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Chat Found")
                    }else{
                        self.TableViewRemoveNoDataLable(tableview: self.tableView)
                    }
                    self.stopLoader()
                    self.tableView.reloadData()
                    return
                }
                var message1 = try! FirebaseDecoder().decode(Chat.self, from: value1)
                message1.chat_id = key
                message1.user?.uid = key
                self.chats.append(message1)
            }
            self.chats = self.chats.filter { chat in
                chat.is_request_accepted ?? false
            }
            
            self.chats = self.chats.sorted(by: { (message1, message2) -> Bool in
                guard let time1 = message1.time, let time2 = message2.time else {
                    return false
                }
                return time1 > time2
            })
            if self.chats.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Chat Found")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
            
            self.groupMessages()
        }
    }
    func groupMessages(){
        Database.database().reference().child("chats").queryOrdered(byChild: "is_group").queryEqual(toValue: true).observe(.value) { snapshot in
            guard let value = snapshot.value as? [String:Any] else {
                if self.chats.isEmpty{
                    self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Chat Found")
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
                        self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Chat Found")
                    }else{
                        self.TableViewRemoveNoDataLable(tableview: self.tableView)
                    }
                    self.stopLoader()
                    self.tableView.reloadData()
                    return
                }
                var message1 = try! FirebaseDecoder().decode(Chat.self, from: value1)
                message1.group_id = key
                message1.chat_id = key
                let user_exists = message1.group_users?.contains(where: { user in
                    user.uid == Auth.auth().currentUser?.uid
                })
                
                if (user_exists ?? false){
                    self.chats.append(message1)
                }
            }
            
            self.chats = self.chats.sorted(by: { (message1, message2) -> Bool in
                guard let time1 = message1.time, let time2 = message2.time else {
                    return false
                }
                return time1 > time2
            })
            if self.chats.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Chat Found")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
            self.stopLoader()
            
            self.chats = self.chats.unique(selector: { chat, chat1 in
                chat.chat_id == chat1.chat_id
            })
            
            self.tableView.reloadData()
        }
    }
        
    @IBAction func newChatButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: NewChatViewController.self)) as! NewChatViewController
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension MyChatViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchTextEmpty ? chats.count : searchedChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyChatTableViewCell") as? MyChatTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.delegate = self
        cell.button.tag = indexPath.row
        if isSearchTextEmpty ? chats.count == 0 : searchedChats.count == 0{
            return UITableViewCell()
        }
        if isSearchTextEmpty ? chats[indexPath.row].is_group ?? false : searchedChats[indexPath.row].is_group ?? false{
            if isSearchTextEmpty{
                cell.setupUser(data: chats[indexPath.row],isGroup: true)
            }else{
                cell.setupUser(data: searchedChats[indexPath.row],isGroup: true)
            }
        }else{
            if isSearchTextEmpty{
                cell.setupUser(data: chats[indexPath.row], isGroup: false)
            }else{
                cell.setupUser(data: searchedChats[indexPath.row], isGroup: false)
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
extension MyChatViewController: MyChatTableViewCellDelegate{
    func openUserProfile(index: Int) {
        if Auth.auth().currentUser?.uid ?? "" == chats[index].user?.uid ?? ""{
            self.tabBarController?.selectedIndex = 4
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        vc.fromOtherUserProfile = true
        vc.userID = chats[index].user?.uid ?? ""
        vc.index = index
        vc.otherUser = chats[index].user
        self.navigationController?.pushViewController(vc, animated: true)
    }
}


extension Array {
    func unique(selector:(Element,Element)->Bool) -> Array<Element> {
        return reduce(Array<Element>()){
            if let last = $0.last {
                return selector(last,$1) ? $0 : $0 + [$1]
            } else {
                return [$1]
            }
        }
    }
}
