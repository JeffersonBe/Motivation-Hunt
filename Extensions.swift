//
//  Colors.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 08/05/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import UIKit
import SwiftyUserDefaults

extension UIColor {
    static func blackTransparentColor() -> UIColor {
        return UIColor(red:0.08, green:0.08, blue:0.08, alpha:1.00)
    }
}

extension UIImage {
    static func fromColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

// NSUserDefaults
extension DefaultsKeys {
    static let haveSeenOnBoarding = DefaultsKey<Bool?>("haveSeenOnBoarding")
}
