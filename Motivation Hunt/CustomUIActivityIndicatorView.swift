//
//  CustomUIActivityIndicatorView.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 05/03/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit

class CustomUIActivityIndicatorView : UIView {
    fileprivate var blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    fileprivate var spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    var isActive: Bool = false

    override init (frame : CGRect) {
        super.init(frame : frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    func startActivity() {
        let x = UIScreen.main.bounds.width/2
        let y = UIScreen.main.bounds.height/2

        blur.frame = CGRect(x: 100, y: 100, width: 150, height: 150)
        blur.layer.cornerRadius = 10
        blur.center = CGPoint(x: x, y: y)
        blur.clipsToBounds = true

        spinner.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        spinner.isHidden = false
        spinner.center = CGPoint(x: x, y: y)
        spinner.startAnimating()

        super.addSubview(blur)
        super.addSubview(spinner)
        isActive = true
    }

    func stopActivity() {
        blur.removeFromSuperview()
        spinner.removeFromSuperview()
        isActive = false
    }
}
