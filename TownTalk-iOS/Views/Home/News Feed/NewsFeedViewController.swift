//
//  NewsFeedViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/03/2023.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

protocol NewsFeedViewControllerDelegate{
    func searchPressed()
    func notificationPressed()
    func editPressed()
    func addNewsFeed(feeds: [Feed])
    func selectedNewsFeed(feed: Feed)
    func addUsers(feed: Feed)
    func allNewsFeed()
    func deletedFeed(feed:Feed)
}

class NewsFeedViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var blurView: UIView!
    
    var locationname = ""
    var users = [User]()
    var feeds = [Feed]()
    
    var delegate: NewsFeedViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.getAllUsers { users in
            self.users = users
        }
        
        tableViewHeightConstraint.constant = 160 + 72
        setView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getFeedsForCurrentUser()
    }
    
    private func setView(){
        registerNibs()
        addGesture()
    }
    
    func getFeedsForCurrentUser() {
        self.startLoader()
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        guard Utils.shared.isInternetAvailable() else {
                    self.alert(title: "Error", message: "No Internet Available")
                    return
                }
        let usersRef = Database.database().reference().child("users")
        let currentUserRef = usersRef.child(currentUserID)
        
        currentUserRef.observeSingleEvent(of: .value) { (snapshot,error) in
            guard let userData = snapshot.value as? [String: Any],
                  let feedsData = userData["feeds"] as? [[String: Any]] else {
                self.stopLoader()
                return
            }
            for feedData in feedsData {
                let feedName = feedData["feed_name"] as? String ?? ""
                let feedID = feedData["id"] as? Int ?? 0
                if let usersData = feedData["users"] as? [[String: Any]] {
                    var users: [User] = []
                    for userData in usersData {
                        let email = userData["email"] as? String ?? ""
                        let fullName = userData["fullName"] as? String ?? ""
                        let isSelected = userData["isSelected"] as? Bool ?? false
                        let phone = userData["phone"] as? String ?? ""
                        let profilePic = userData["profile_pic"] as? String ?? ""
                        let username = userData["username"] as? String ?? ""
                        let zipCode = userData["zip_code"] as? String ?? ""
                        let uid = userData["uid"] as? String ?? ""
                        
                        let user = User(profile_pic: profilePic, username: username, email: email, phone: phone, zip_code: zipCode, fullName: fullName,isSelected: isSelected,uid: uid)
                        users.append(user)
                    }
                    
                    let feed = Feed(feed_name: feedName, id: feedID, users: users)
                    self.feeds.append(feed)
                }else{
                    let feed = Feed(feed_name: feedName,id: feedID)
                    self.feeds.append(feed)
                }
                
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.stopLoader()
            }
        } withCancel: { error in
            self.stopLoader()
            print("Error fetching feeds for current user: \(error.localizedDescription)")
            return
        }
    }
    
    private func registerNibs(){
        tableView.register(UINib(nibName: String(describing: NewsFeedTopHeader.self), bundle: nil), forCellReuseIdentifier: String(describing: NewsFeedTopHeader.self))
        tableView.register(UINib(nibName: String(describing: NewsFeedTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: NewsFeedTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: NewsFeedBottomView.self), bundle: nil), forCellReuseIdentifier: String(describing: NewsFeedBottomView.self))
    }
    func addGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        blurView.addGestureRecognizer(tap)
    }
    @objc func dismissView(){
        self.dismiss(animated: true)
    }
}

extension NewsFeedViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewHeightConstraint.constant = 160+(67*5)+72+10
        switch section{
        case 0:
            return 1
        case 1:
            return feeds.count
        case 2:
            return 1
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section{
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NewsFeedTopHeader.self)) as? NewsFeedTopHeader else { return UITableViewCell() }
            cell.delegate = self
            cell.lblLocation.text = locationname
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NewsFeedTableViewCell.self)) as? NewsFeedTableViewCell else { return UITableViewCell() }
            cell.delegate = self
            cell.moreBtn.tag = indexPath.row
            cell.lblTitle.text = feeds[indexPath.row].feed_name
            cell.addUserBtn.isHidden = feeds[indexPath.row].feed_name == "News Feed"
            cell.moreBtn.isHidden = feeds[indexPath.row].feed_name == "News Feed"
            cell.feed = feeds[indexPath.row]
            return cell
        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NewsFeedBottomView.self)) as? NewsFeedBottomView else { return UITableViewCell() }
            return cell
        default:
            return UITableViewCell()
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section{
        case 0:
            return 160
        case 1:
            tableViewHeightConstraint.constant = CGFloat((feeds.count * 67) + 160 + 72)
            return 67
        case 2:
            if self.feeds.count < 5{
                return 72
            }else{
                return 0
            }
        default:
            return 0
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2{
            self.dismiss(animated: true) {
                self.delegate?.addNewsFeed(feeds: self.feeds)
            }
        }
        if indexPath.section == 1{
            self.dismiss(animated: true) {
                self.delegate?.selectedNewsFeed(feed: self.feeds[indexPath.row])
            }
        }
    }
}

extension NewsFeedViewController: NewsFeedTopHeaderDelegate{
    func allNewsFeed() {
        self.dismiss(animated: true) {
            self.delegate?.allNewsFeed()
        }   
    }
    func clossSheet() {
        self.dismissView()
    }
    func searchPressed() {
        delegate?.searchPressed()
    }
    func editPressed() {
        self.dismiss(animated: true) {
            self.delegate?.editPressed()
        }
    }
    func notificationPressed() {
        delegate?.notificationPressed()
    }
    
}
extension NewsFeedViewController: NewsFeedTableViewCellDelegate{
    func addUsers(feed: Feed) {
        self.dismiss(animated: true) {
            self.delegate?.addUsers(feed: feed)
        }
        
    }
    func moreOptionsSelected(feed: Feed, index: Int) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .default , handler: { (UIAlertAction) in
            guard Utils.shared.isInternetAvailable() else {
                        self.alert(title: "Error", message: "No Internet Available")
                        return
                    }
            let ref = Database.database().reference().child("users").child(Auth.auth().currentUser?.uid ?? "")
            self.feeds.remove(at: index)
            let dict = ["feeds" :
                            self.feeds.map { feed in
                feed.dictionary
            }
            ]
            ref.updateChildValues(dict) { error, _ in
                if error == nil{
                    self.delegate?.deletedFeed(feed: feed)
                    self.tableView.reloadData()
                }else{
                    print(error?.localizedDescription ?? "")
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        alert.popoverPresentationController?.sourceView = self.view
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
}
