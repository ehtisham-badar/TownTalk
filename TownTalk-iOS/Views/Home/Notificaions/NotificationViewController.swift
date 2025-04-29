//
//  NotificationViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import CodableFirebase

class NotificationViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var notifications = [AppNotification]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        getNotifications()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.tableView.reloadData()
    }
    
    private func setView(){
        registerNibs()
    }
    private func registerNibs(){
        tableView.register(UINib(nibName: String(describing: NotificationTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: NotificationTableViewCell.self))
    }
    
    func getNotifications(){
        self.startLoader()
        Database.database().reference().child("notifications").child(Auth.auth().currentUser?.uid ?? "").observe(.value) { snapshot in
            self.notifications.removeAll()
            if let value = snapshot.value as? [String:Any]{
                value.forEach { (key: String, value: Any) in
                    if let value = value as? [String:Any]{
                        var notification = try! FirebaseDecoder().decode(AppNotification.self, from: value)
                        notification.notification_id = key
                        if let user = Utils.getUser(user_id: notification.user_id ?? "") {
                            if user == nil{
                                
                            }else{
                                self.notifications.append(notification)
                            }
                        }
                        
                    }
                }
                if self.notifications.isEmpty{
                    self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Notification")
                }else{
                    self.TableViewRemoveNoDataLable(tableview: self.tableView)
                }
                self.notifications.sort(by: { $0.time!.compare($1.time ?? "") == .orderedDescending })
                self.stopLoader()
                self.tableView.reloadData()
            }else{
                if self.notifications.isEmpty{
                    self.TableViewNoDataAvailabl(tableview: self.tableView, text: "No Notification")
                }else{
                    self.TableViewRemoveNoDataLable(tableview: self.tableView)
                }
                self.stopLoader()
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension NotificationViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self)) as? NotificationTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.setTraits()
        cell.imgView.tag = indexPath.row
        cell.delegate = self
        cell.setCell(data: self.notifications[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.startLoader()
        Database.database().reference().child("notifications").child(Auth.auth().currentUser?.uid ?? "").child(self.notifications[indexPath.row].notification_id ?? "").updateChildValues(["is_read": true]) { error, snapshot in
            if error == nil{
                self.stopLoader()
                let storyboard = UIStoryboard(name: "Post", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: String(describing: PostDetailViewController.self)) as! PostDetailViewController
                vc.post_id = self.notifications[indexPath.row].post_id ?? ""
                vc.userid = self.notifications[indexPath.row].sender_user_id ?? ""
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                self.stopLoader()
            }
        }
    }
}
extension NotificationViewController: NotificationTableViewCellDelegate{
    func openProfile(user_id: String,index: Int) {
        if Auth.auth().currentUser?.uid ?? "" == (user_id){
            self.tabBarController?.selectedIndex = 4
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        vc.fromOtherUserProfile = true
        vc.userID = user_id
        vc.index = index
        vc.otherUser = Utils.getUser(user_id: user_id)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
