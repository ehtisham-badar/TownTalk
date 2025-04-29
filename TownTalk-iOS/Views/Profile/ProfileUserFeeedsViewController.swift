//
//  ProfileUserFeeedsViewController.swift
//  TownTalk-iOS
//
//  Created by Veripark on 01/09/2023.
//



protocol ProfileUserFeeedDelegate: AnyObject {
    func profileUserCreateNewFeeedPassed(feedList_obbject: [Feed])
    func profileEditFeedPassed(feedList_obbject: [Feed] , editableFeed:Feed)
}




import UIKit

class ProfileUserFeeedsViewController: BaseViewController {
    
    @IBOutlet weak var feeds_tableView: UITableView!
    @IBOutlet weak var main_view: UIView!
    var loggedInUserCurrentFeeds: [Feed]  = []
    weak var delegate: ProfileUserFeeedDelegate?


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupController()
        
    }
    
    func setupController(){
        feeds_tableView.dataSource = self
        setupUIViews()
        setUpFeedList()
    }
    
    func setupUIViews(){
        main_view.roundCorners(corners: [.topLeft, .topRight], radius: 20.0)
    }
    
    func setUpFeedList(){
        let currectEmail = Utils.user?.email ?? ""
        if let matchingUser =  Constants.users.first(where: { $0.email == currectEmail }) {
            print("Matching User: \(matchingUser)")
            self.loggedInUserCurrentFeeds = matchingUser.feeds ?? []
            self.loggedInUserCurrentFeeds.append(Feed(feed_name: "Create New Feed"))
            self.feeds_tableView.reloadData()
        } else {
            // No matching user found
            print("User with ID \(currectEmail) not found.")
        }
    }
    

}



extension ProfileUserFeeedsViewController :   UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loggedInUserCurrentFeeds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserFeedTitleCell", for: indexPath) as! UserFeedTitleCell
        cell.titleFeed.text = loggedInUserCurrentFeeds[indexPath.row].feed_name
        
        if ( loggedInUserCurrentFeeds[indexPath.row].feed_name  == "Create New Feed" ) {
            cell.addUserToFeed.isHidden = true
        }else{
            cell.create_NewFeed.isHidden = true
        }
        
        cell.addUserToFeed_tap = {
            self.dismiss(animated: true) {
                self.delegate?.profileEditFeedPassed(feedList_obbject:self.loggedInUserCurrentFeeds, editableFeed: self.loggedInUserCurrentFeeds[indexPath.row])
            }
            
        }
        
        cell.createNewFeed_tap = {
            self.dismiss(animated: true) {
                self.delegate?.profileUserCreateNewFeeedPassed(feedList_obbject:self.loggedInUserCurrentFeeds)
            }
        }
        
        return cell
    }
    

    
}

