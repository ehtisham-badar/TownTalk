//
//  Login.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//


import UIKit

extension UIFont{
    static var diodrumSemiBold: UIFont?{
        return UIFont(name: "DiodrumArabic-Semibold", size: UIDevice.current.userInterfaceIdiom == .pad ? 22 : 13)
    }
    
    static func diodriumMedium(withSize: CGFloat) -> UIFont?{
        return UIFont(name: "DiodrumArabic-Medium", size: withSize)
    }
    
    static func diodrumSemiBold(withSize: CGFloat) -> UIFont?{
        return UIFont(name: "DiodrumArabic-Semibold", size: withSize)
    }
    static func satoshiRegular(withSize: CGFloat) -> UIFont?{
        return UIFont(name: "Satoshi-Regular", size: withSize)
    }
    static func satoshiBold(withSize: CGFloat) -> UIFont?{
        return UIFont(name: "Satoshi-Bold", size: withSize)
    }
    static func satoshiMedium(withSize: CGFloat) -> UIFont?{
        return UIFont(name: "Satoshi-Medium", size: withSize)
    }
    
    static func diodrumBold(withSize: CGFloat) -> UIFont?{
        return UIFont(name: "DiodrumArabic-Bold", size: withSize)
    }
    
    static func robotoBold(withSize: CGFloat) -> UIFont?{
        return UIFont(name: "Roboto-Bold", size: withSize)
    }
    static func robotoRegular(withSize: CGFloat) -> UIFont?{
        return UIFont(name: "Roboto-Regular", size: withSize)
    }
}

