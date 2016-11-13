//
//  MotivationCollectionViewCell.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 19/04/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import SnapKit
import XCDYouTubeKit
import IoniconsSwift

class MotivationCollectionViewCell: UICollectionViewCell {
    
    var titleBarView: UIView!
    var textLabel: UILabel!
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(contentView)
            make.width.equalTo(contentView)
            // Calculation to keep 16:9 ratio
            make.height.equalTo((contentView.frame.width / 16) * 9)
            make.top.equalTo(contentView)
        }
        
        titleBarView = UIView()
        contentView.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom)
            make.width.equalTo(contentView.frame.width - 20)
            make.height.equalTo(44)
            make.centerX.equalTo(contentView)
        }
        
        textLabel = UILabel()
        textLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        textLabel.textAlignment = .center
        titleBarView.addSubview(textLabel)
        textLabel.snp.makeConstraints { (make) in
            make.width.equalTo(titleBarView)
            make.center.equalTo(titleBarView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
