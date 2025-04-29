//
//  UINavigationController+LC.swift
//  TownTalk-iOS
//
//  Created by Ehtisham Badar on 20/03/2023.
//

import Foundation
import UIKit

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func transparentNavigationBar() {
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.view.backgroundColor = .clear
    }
    
    func setAttributedTitle() {
        let attributes = [NSAttributedString.Key.font: UIFont.appThemeFontWithSize(19.0), NSAttributedString.Key.foregroundColor: UIColor.white] //change size as per your need here.
        self.navigationBar.titleTextAttributes = attributes
    }
    
    func setupAppThemeNavigationBar() {
        navigationBar.isTranslucent = false
        navigationBar.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        navigationBar.tintColor = .white
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.appThemeBoldFontWithSize(20.0)]
    }
    
    func setUpTransparentNavigation() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.tintColor = .black
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        self.modalPresentationStyle = .fullScreen
        //        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "SegoeUI-SemiBold", size: 18)!]
        view.backgroundColor = .clear
    }
    
}
extension UIFont {
    
    class func appThemeFontWithSize(_ fontSize: CGFloat) -> UIFont {
        
        if let font = UIFont(name: "Mark Pro", size: fontSize) {
            return font
        }
        
        return UIFont.systemFont(ofSize: fontSize)
    }
    
    class func appThemeBoldFontWithSize(_ fontSize: CGFloat) -> UIFont {
        
        if let font = UIFont(name: "MarkPro-Bold", size: fontSize) {
            return font
        }
        
        return UIFont.systemFont(ofSize: fontSize)
    }
    
    class func appThemeSemiBoldFontWithSize(_ fontSize: CGFloat) -> UIFont {
        
        if let font = UIFont(name: "MarkPro-Book", size: fontSize) {
            return font
        }
        
        return UIFont.systemFont(ofSize: fontSize)
    }
    
    class func sevenSegmentFontWithSize(_ fontSize: CGFloat) -> UIFont {
        
        if let font = UIFont(name: "Mark Pro Semi Bold", size: fontSize) {
            return font
        }
        
        return UIFont.systemFont(ofSize: fontSize)
    }
    class func poppinsSemiBoldwithSize(_ fontSize: CGFloat) -> UIFont {
        
        if let font = UIFont(name: "Poppins-SemiBold", size: fontSize) {
            return font
        }
        
        return UIFont.systemFont(ofSize: fontSize)
    }
    
    class func poppinsRegularWithSize(_ fontSize: CGFloat) -> UIFont {
        
        if let font = UIFont(name: "Poppins-Regular", size: fontSize) {
            return font
        }
        
        return UIFont.systemFont(ofSize: fontSize)
    }
}

