//
//  challengeTableViewCell.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 05/03/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit

class challengeTableViewCell: UITableViewCell {
    var challengeDescriptionTextLabel: UILabel!
    var challengeDateTextLabel: UILabel!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        challengeDescriptionTextLabel = UILabel()
        challengeDescriptionTextLabel.textColor = UIColor.blackColor()
        contentView.addSubview(challengeDescriptionTextLabel)
        challengeDescriptionTextLabel.snp_makeConstraints { (make) in
            make.top.equalTo(10)
            make.left.equalTo(15)
            make.height.equalTo(20)
        }

        challengeDateTextLabel = UILabel()
        challengeDateTextLabel.textColor = UIColor.blackColor()
        contentView.addSubview(challengeDateTextLabel)
        challengeDateTextLabel.snp_makeConstraints { (make) in
            make.top.equalTo(challengeDescriptionTextLabel.snp_bottom).offset(5)
            make.left.equalTo(15)
            make.height.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
