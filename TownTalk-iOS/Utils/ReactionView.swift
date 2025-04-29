//
//  ReactionView.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 25/05/2023.
//

import UIKit

enum ReactionType: String {
    case like = "👍"
    case love = "♥️"
    case angry = "😠"
    case sad = "🙁"
    
    static func get(value: String) -> String {
        switch value {
        case "like":
            return "👍"
        case "love":
            return "♥️"
        case "angry":
            return "😠"
        case "sad":
            return "🙁"
        default:
            return ""
        }
    }
}

class ReactionView: UIView {
    
    @IBOutlet weak var stackView: UIStackView!
    
    var onReaction: ((ReactionType) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViewWithNib()
        doAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initViewWithNib()
    }
    
    func doAnimation() {
//        let offset = CGPoint(x: UIScreen.main.bounds.width, y: 0)
//        self.transform = CGAffineTransform(translationX: offset.x, y: offset.y)
//        UIView.animate(withDuration: 1,
//                       delay: 0,
//                       usingSpringWithDamping: 1,
//                       initialSpringVelocity: 1,
//                       options: .curveEaseOut,
//                       animations: {
//            self.transform = .identity
//            self.alpha = 1
//        },
//                       completion: { [weak self] _ in
//            guard let self = self else { return }
//            self.stackView.arrangedSubviews.forEach { view in
//                UIView.animate(withDuration: 0.5,
//                               delay: 0.0,
//                               options: .curveEaseIn,
//                               animations: {
//                    view.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
//                }, completion: { _ in
//                    UIView.animate(withDuration: 0.5, animations: {
//                        view.transform = .identity
//                    })
//                })
//            }
//        })
    }
    
    @IBAction func doLike(_ sender: Any) {
        onReaction?(.like)
        Utils.logFirebaseEvent(eventName: "like_message")
    }
    @IBAction func doLove(_ sender: Any) {
        onReaction?(.love)
        Utils.logFirebaseEvent(eventName: "love_message")
    }
    @IBAction func doAngry(_ sender: Any) {
        onReaction?(.angry)
        Utils.logFirebaseEvent(eventName: "angt_message")
    }
    @IBAction func doSad(_ sender: Any) {
        onReaction?(.sad)
        Utils.logFirebaseEvent(eventName: "sad_message")
    }
    
}

extension UIView {
    
    func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: "ReactionView", bundle: nil)
        return nib.instantiate(
            withOwner: self,
            options: nil).first as? UIView
    }
    
    func initViewWithNib() {
        guard let view = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask =
        [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
}
