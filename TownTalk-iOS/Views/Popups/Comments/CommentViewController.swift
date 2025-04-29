//
//  CommentViewController.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 04/04/2023.
//

import UIKit

protocol CommentViewControllerDelegate{
    func addComment(text: String,post: inout Post,index: Int)
}

class CommentViewController: UIViewController {
    
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var commentTF: UITextField!
    
    var delegate: CommentViewControllerDelegate?
    var post: Post!
    var index: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGesture()
        
        self.logPageView()
    }
    func addGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        blurView.addGestureRecognizer(tap)
    }
    @objc func dismissView(){
        self.dismiss(animated: true)
    }
    @IBAction func didPressPostButton(_ sender: Any) {
        self.dismiss(animated: true) { [self] in
            self.delegate?.addComment(text: self.commentTF.text ?? "",post: &post,index: index)
        }
    }
}
