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
    static func fromColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    func imageWith(size: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth:CGFloat = size.width / size.width
        let aspectHeight:CGFloat = size.height / size.height
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = size.width * aspectRatio
        scaledImageRect.size.height = size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        draw(in: scaledImageRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysTemplate)
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}

// NSUserDefaults
extension DefaultsKeys {
    static let haveSeenOnBoarding = DefaultsKey<Bool?>("haveSeenOnBoarding")
}

extension Date {
     static public func ==(lhs: Date, rhs: Date) -> Bool {
        return lhs == rhs || lhs.compare(rhs) == .orderedSame
    }
    
    static public func <(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
}

extension UIWindow {
    
    func visibleViewController() -> UIViewController? {
        if let rootViewController: UIViewController  = self.rootViewController {
            return UIWindow.getVisibleViewController(from: rootViewController)
        }
        return nil
    }
    
    class func getVisibleViewController(from viewController:UIViewController) -> UIViewController {
        if viewController.isKind(of: UINavigationController.self) {
            let navigationController = viewController as! UINavigationController
            return UIWindow.getVisibleViewController(from: navigationController.visibleViewController!)
        } else if viewController.isKind(of: UITabBarController.self) {
            let tabBarController = viewController as! UITabBarController
            return UIWindow.getVisibleViewController(from: tabBarController.selectedViewController!)
            
        } else {
            if let presentedViewController = viewController.presentedViewController {
                return UIWindow.getVisibleViewController(from: presentedViewController.presentedViewController!)
            } else {
                return viewController
            }
        }
    }
}

extension Date {
    func add(minutes: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .minute, value: minutes, to: self)!
    }
}
