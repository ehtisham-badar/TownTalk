//
//  Login.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//

import UIKit

extension UILabel {
    func setTextWhileKeepingAttributes(string: String) {
        if let newAttributedText = self.attributedText {
            let mutableAttributedText = newAttributedText.mutableCopy()
            
            (mutableAttributedText as AnyObject).mutableString.setString(string)
            
            self.attributedText = mutableAttributedText as? NSAttributedString
        }
    }
//    @IBInspectable var lineSpacing : CGFloat{
//        set{
//            if let text = self.text{
//                let attribText = NSMutableAttributedString(string: text)
//                let paragraphStyle = NSMutableParagraphStyle()
//                paragraphStyle.lineSpacing = newValue //direct set Default value
//                attribText.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attribText.length))
//                self.attributedText = attribText
//            }
//        }
//
//        get{
//            return 0
//        }
//    }
}
