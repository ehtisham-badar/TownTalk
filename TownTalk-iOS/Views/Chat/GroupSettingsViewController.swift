//
//  GroupSettingsViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/05/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

protocol GroupSettingsViewControllerDelegate{
    func updateUserList(chat: Chat)
}

class GroupSettingsViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblGroupName: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var addMemberView: UIView!
    @IBOutlet weak var heigthConstraint: NSLayoutConstraint!
    @IBOutlet weak var leaveButton: UIButton!
    @IBOutlet weak var editIcon: UIImageView!
    
    var groupData: Chat?
    var delegate: GroupSettingsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNibs()
        
        lblGroupName.text = groupData?.group_name ?? ""
        Utils.loadImage(imageView: groupImage, urlString: groupData?.group_image ?? "", placeHolder: UIImage(named: "placeholder"))
        tableView.reloadData()
        self.groupData?.group_users?.forEach { user in
            if (Auth.auth().currentUser?.uid ?? "") == user.uid && user.is_admin != nil {
                addMemberView.isHidden = false
                heigthConstraint.constant = 50
                leaveButton.setTitle("Remove Group", for: .normal)
                self.editIcon.isHidden = false
                return
            }
        }
    }
    func registerNibs(){
        tableView.register(UINib(nibName: String(describing: MyChatTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: MyChatTableViewCell.self))
    }
    @IBAction func changeGroupImage(_ sender: Any) {
        for i in 0..<(self.groupData?.group_users?.count ?? 0){
            if (Auth.auth().currentUser?.uid ?? "" == self.groupData?.group_users?[i].uid) && self.groupData?.group_users?[i].is_admin != nil{
                PhotoPicker.shared.delegate = self
                PhotoPicker.shared.pickPhoto(with: self)
            }else{
                
            }
        }
        
    }
    @IBAction func leaveGroupButtonPressed(_ sender: Any) {
        if leaveButton.title(for: .normal) == "Remove Group"{
            Database.database().reference().child("chats").child(self.groupData?.group_id ?? "").removeValue { error, ref in
                if error == nil{
                    for controller in self.navigationController!.viewControllers as Array {
                        if controller.isKind(of: TabBarController.self) {
                            self.navigationController!.popToViewController(controller, animated: true)
                            break
                        }
                    }
                }
            }
        }else{
            
            guard let index = self.groupData?.group_users?.firstIndex(where: { user in
                user.uid == Auth.auth().currentUser?.uid ?? ""
            }) else { return }
            self.groupData?.group_users?.remove(at: index)
            Database.database().reference().child("chats").child(self.groupData?.group_id ?? "").updateChildValues(["group_users": self.groupData!.group_users!.map({ user in
                user.dictionary
            })]) { error, ref in
                if error == nil{
                    for controller in self.navigationController!.viewControllers as Array {
                        if controller.isKind(of: TabBarController.self) {
                            self.navigationController!.popToViewController(controller, animated: true)
                            break
                        }
                    }
                }
            }
        }
    }
    @IBAction func addMembers(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: AddUsersViewController.self)) as! AddUsersViewController
        vc.isFromEdit = true
        vc.groupData = groupData
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension GroupSettingsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupData?.group_users?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MyChatTableViewCell.self)) as! MyChatTableViewCell
        cell.selectionStyle = .none
        cell.delegate = self
        cell.button.tag = indexPath.row
        cell.setUserCells(user: (groupData?.group_users?[indexPath.row])!)
        cell.lblTime.isHidden = (groupData?.group_users?[indexPath.row].is_admin ?? false) ? false : true
        cell.lblTime.text = (groupData?.group_users?[indexPath.row].is_admin ?? false) ? "Admin" : ""
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        print("swipe")
        if leaveButton.title(for: .normal) != "Remove Group"{
            return UISwipeActionsConfiguration()
        }
        if Auth.auth().currentUser?.uid ?? "" != self.groupData?.group_users?[indexPath.row].uid ?? "" && self.groupData?.group_users?[indexPath.row].is_admin == nil{
            let removeAction = UIContextualAction(style: .destructive, title: "Remove") { (action, view, completionHandler) in
                self.groupData?.group_users?.remove(at: indexPath.row)
                Database.database().reference().child("chats").child(self.groupData?.group_id ?? "").updateChildValues(["group_users": self.groupData!.group_users!.map({ user in
                    user.dictionary
                })]) { error, ref in
                    if error == nil{
                        print("deleted")
                        self.delegate?.updateUserList(chat: self.groupData!)
                    }
                }
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                completionHandler(true)
            }
            let swipeConfiguration = UISwipeActionsConfiguration(actions: [removeAction])
            swipeConfiguration.performsFirstActionWithFullSwipe = false // Allow partial swipe
            
            return swipeConfiguration
        }else{
            return UISwipeActionsConfiguration()
        }
    }
}
extension GroupSettingsViewController: PhotoPickerDelegate{
    func didFinish(image: UIImage) {
        
        self.groupImage.image = image
        self.startLoader()
        self.uploadImage(child: "group_images", _image: image) { url in
            Database.database().reference().child("chats").child(self.groupData?.group_id ?? "").updateChildValues(["group_image": url?.absoluteString ?? ""]) { error, ref in
                if error == nil{
                    self.stopLoader()
                }
            }
        }
    }
}
extension GroupSettingsViewController :AddUsersViewControllerDelegate{
    func updateUserList(users: [User]) {
        self.groupData?.group_users = users
        self.tableView.reloadData()
    }
}
extension GroupSettingsViewController: MyChatTableViewCellDelegate{
    func openUserProfile(index: Int) {
        if Auth.auth().currentUser?.uid ?? "" == self.groupData?.group_users?[index].uid{
            self.tabBarController?.selectedIndex = 4
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: MYProfileViewController.self)) as! MYProfileViewController
        vc.fromOtherUserProfile = true
        vc.userID = self.groupData?.group_users?[index].uid ?? ""
        vc.index = index
        vc.otherUser = self.groupData?.group_users?[index]
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
