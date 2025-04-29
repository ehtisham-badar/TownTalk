//
//  UIDevice + Extensions.swift
//  Almoosa
//
//  Created by Ehtisham Badar on 20/07/2022.
//

import Foundation
import UIKit

extension UIDevice {
    var hasNotch: Bool {
        guard #available(iOS 11.0, *), let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first else { return false }
        //uncomment if landscape is on
        return window.safeAreaInsets.top >= 44
    }
}
