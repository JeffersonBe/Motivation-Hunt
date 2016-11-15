//
//  ChallengeTableViewCell.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 08/11/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit

class challengeTableViewCell: UITableViewCell {
    var challengeDescriptionTextLabel: UILabel!
    var challengeDateTextLabel: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        challengeDescriptionTextLabel = UILabel()
        challengeDescriptionTextLabel.textColor = UIColor.black
        contentView.addSubview(challengeDescriptionTextLabel)
        challengeDescriptionTextLabel.snp.makeConstraints { (make) in
            make.top.equalTo(10)
            make.left.equalTo(15)
            make.height.equalTo(50)
            make.width.equalTo(self).inset(15)
        }
        
        challengeDateTextLabel = UILabel()
        challengeDateTextLabel.textColor = UIColor.black
        contentView.addSubview(challengeDateTextLabel)
        challengeDateTextLabel.snp.makeConstraints { (make) in
            make.top.equalTo(challengeDescriptionTextLabel.snp.bottom).offset(5)
            make.left.equalTo(15)
            make.height.equalTo(50)
            make.width.equalTo(self).inset(15)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
