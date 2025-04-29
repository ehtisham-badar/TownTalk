//
//  Login.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 04/07/2022.
//

import Foundation
import UIKit

extension UIScrollView{
    public var currentPage: Int {
        get {
            let x = self.contentOffset.x
            let w = self.bounds.size.width
            return Int(ceil(x/w))
        }
    };
}
