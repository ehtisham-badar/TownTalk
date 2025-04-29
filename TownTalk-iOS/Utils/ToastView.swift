//
//  ToastView.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 02/06/2023.
//

import UIKit

class ToastView: UIView {
    static let shared = ToastView()
    
    private var toastLabel: UILabel!
    
    private init() {
        super.init(frame: CGRect.zero)
        
        let toastHeight: CGFloat = 50.0
        let toastBackgroundColor = UIColor.black.withAlphaComponent(0.7)
        let toastTextColor = UIColor.white
        let toastFont = UIFont.systemFont(ofSize: 16.0)
        
        toastLabel = UILabel(frame: CGRect(x: 16.0, y: 0, width: UIScreen.main.bounds.width - 32.0, height: toastHeight))
        toastLabel.backgroundColor = toastBackgroundColor
        toastLabel.textColor = toastTextColor
        toastLabel.font = toastFont
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10.0
        toastLabel.clipsToBounds = true
        
        self.addSubview(toastLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showToast(message: String, duration: TimeInterval = 2.0) {
        DispatchQueue.main.async {
            self.toastLabel.text = message
            
            UIView.animate(withDuration: 0.3, animations: {
                self.toastLabel.alpha = 1.0
            }) { (_) in
                UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                    self.toastLabel.alpha = 0.0
                }, completion: nil)
            }
        }
    }
}
