//
//  ShareWithContactsViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 23/03/2023.
//

import UIKit
import MBProgressHUD
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase

protocol ShareWithContactsViewControllerDelegate{
    func sharePostInMessages(chat: Chat,post: Post)
}

class ShareWithContactsViewController: BaseViewController {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var bottomConstraintToAnimate: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: ShareWithContactsViewControllerDelegate?
    var users = [User]()
    var post: Post!
    var chats = [Chat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bottomConstraintToAnimate.constant = -450
        addGesture()
        setView()
        registerNibs()
        getUsers()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        animatePopup()
    }
    
    func getUsers(){
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
            self.tableView.reloadData()
            self.stopLoader()
        }
    }
    
    func animatePopup(){
        UIView.animate(withDuration: 2.0, delay: 0.1, usingSpringWithDamping: 0.0, initialSpringVelocity: 0.1, options: .curveEaseIn) {
            self.bottomConstraintToAnimate.constant = 0
        }
    }
    
    private func registerNibs(){
        tableView.register(UINib(nibName: "ShareContactTableViewCell", bundle: nil), forCellReuseIdentifier: "ShareContactTableViewCell")
    }
    
    private func setView(){
        mainView.cornerRadius = 35
        mainView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    func addGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        blurView.addGestureRecognizer(tap)
    }
    @objc func dismissView(){
        self.dismiss(animated: true)
    }
    @IBAction func copyButtonPressed(_ sender: Any) {
        var postLink = "towntalk.com://\(post.post_id)/\(post.user_id)"
        UIPasteboard.general.string = postLink
        let alert = UIAlertController(title: "Copied", message: "Text copied to clipboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension ShareWithContactsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(3,self.chats.count)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareContactTableViewCell") as? ShareContactTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.delegate = self
        cell.setCell(data: chats[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105
    }
    
}
extension ShareWithContactsViewController: ShareContactTableViewCellDelegate{
    func sharePost(chat: Chat) {
        self.dismiss(animated: true) {
            self.delegate?.sharePostInMessages(chat: chat, post: self.post)
        }
    }
}
