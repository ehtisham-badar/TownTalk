//
//  BlockUsersViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 31/05/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase

class BlockUsersViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var users = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNibs()
        fetchUsers()
    }
    func registerNibs(){
        tableView.register(UINib(nibName: String(describing: MyChatTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: MyChatTableViewCell.self))
    }
    
    func fetchUsers(){
        self.startLoader()
        Database.database().reference().child("blocked_users").child(Auth.auth().currentUser?.uid ?? "").observe(.value) { snapshot in
            self.users.removeAll()
            if let snapshot = snapshot.value as? Dictionary<String, Any> {
                snapshot.forEach { (key: String, value: Any) in
                    
                    var user = try! FirebaseDecoder().decode(User.self, from: value)
                    user.uid = key
                    self.users.append(user)
                }
            }
            if self.users.isEmpty{
                self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Users Blocked")
            }else{
                self.TableViewRemoveNoDataLable(tableview: self.tableView)
            }
            self.tableView.reloadData()
            self.stopLoader()
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension BlockUsersViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MyChatTableViewCell.self)) as! MyChatTableViewCell
        cell.selectionStyle = .none
        cell.delegate = self
        cell.unblockbtn.tag = indexPath.row
        cell.unblockbtn.isHidden = false
        cell.setUserCells(user: users[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
extension BlockUsersViewController: MyChatTableViewCellDelegate{
    func unblockUser(index: Int) {
        Database.database().reference().child("blocked_users").child(Auth.auth().currentUser?.uid ?? "").child(users[index].uid ?? "").removeValue { error, ref in
            if error == nil{
                NotificationCenter.default.post(Notification(name: Notification.Name("fetch_posts")))
            }
        }
    }
}
