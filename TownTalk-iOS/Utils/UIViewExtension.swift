//
//  Login.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//

import UIKit

extension UIView{
    
    func layoutIfNeededWithAnimation(duration: TimeInterval?){
        UIView.animate(withDuration: duration ?? 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    func getConstriant(identifier: String) -> NSLayoutConstraint?{
        for constraint in self.constraints {
            if constraint.identifier == identifier{
                return constraint
            }
        }
        return nil
    }
    
    func roundCorners(corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var circle: Bool{
        get{
            return false
        }
        set{
            if newValue{
                layer.cornerRadius = frame.width*0.5
                layer.masksToBounds = true
            }
            
        }
    }
    
    // MARK: - Shadow
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
    func fadeIn(duration: TimeInterval = 0.3){
        UIView.animate(withDuration: duration) {
            self.alpha = 1
        }
    }
    
    func fadeOut(duration: TimeInterval = 0.3){
        UIView.animate(withDuration: duration) {
            self.alpha = 0
        }
    }
    
    func transform(translationX: CGFloat, y: CGFloat, duration: TimeInterval = 0.3){
        UIView.animate(withDuration: duration) {
            self.transform = CGAffineTransform(translationX: translationX, y: y)
        }
    }
    func addBottomShadow() {
        layer.masksToBounds = false
        layer.shadowRadius = 4
        layer.shadowOpacity = 1
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOffset = CGSize(width: 0 , height: 2)
        layer.shadowPath = UIBezierPath(rect: CGRect(x: 0,
                                                     y: bounds.maxY - layer.shadowRadius,
                                                     width: bounds.width,
                                                     height: layer.shadowRadius)).cgPath
    }
   
}

extension UIWindow {
    func snapshot() -> UIImage {

           UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)

           drawHierarchy(in: bounds, afterScreenUpdates: true)

           let result = UIGraphicsGetImageFromCurrentImageContext()

           UIGraphicsEndImageContext()

           return result!

       }

    func replaceRootViewControllerWith(_ replacementController: UIViewController, animated: Bool, completion: (() -> Void)?) {

        let snapshotImageView = UIImageView(image: self.snapshot())

        self.addSubview(snapshotImageView)



        let dismissCompletion = { () -> Void in // dismiss all modal view controllers

            self.rootViewController = replacementController

            self.bringSubviewToFront(snapshotImageView)



            if animated {



                UIView.animate(withDuration: 0.4, animations: { () -> Void in

                    snapshotImageView.alpha = 0

                }, completion: { (success) -> Void in

                    snapshotImageView.removeFromSuperview()

                    completion?()

                })



            } else {

                snapshotImageView.removeFromSuperview()

                completion?()

            }

        }
        if self.rootViewController!.presentedViewController != nil {
            self.rootViewController!.dismiss(animated: false, completion: dismissCompletion)
        } else {
            dismissCompletion()
            
        }

    }

}


