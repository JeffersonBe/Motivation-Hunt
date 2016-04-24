//
//  motivationCollectionViewCell.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 27/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import YouTubePlayer
import SnapKit
import FontAwesome
import Toucan

class motivationCollectionViewCell: UICollectionViewCell {
    var videoPlayer: YouTubePlayerView!

    var titleBarView: UIView!
    var textLabel: UILabel!
    var imageView: UIImageView!

    var playButton: UIButton!

    var barActionView: UIView!
    var favoriteBarButton: UIButton!
    var shareBarButton: UIButton!

    var barButtonColor: UIColor!
    var barButtonSize: CGFloat!

    override init(frame: CGRect) {
        super.init(frame: frame)

        barButtonColor = UIColor.grayColor()
        barButtonSize = 25.00

        titleBarView = UIView()
        titleBarView.backgroundColor = UIColor.clearColor()
        contentView.addSubview(titleBarView)
        titleBarView.snp_makeConstraints { (make) in
            make.top.equalTo(contentView.snp_top)
            make.width.equalTo(contentView.frame.width - 20)
            make.height.equalTo(44)
            make.centerX.equalTo(contentView)
        }

        textLabel = UILabel()
        textLabel.textColor = UIColor.whiteColor()
        textLabel.textAlignment = .Center
        titleBarView.addSubview(textLabel)
        textLabel.snp_makeConstraints { (make) in
            make.width.equalTo(titleBarView)
            make.center.equalTo(titleBarView)
        }

        imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        contentView.addSubview(imageView)
        imageView.snp_makeConstraints { (make) in
            make.top.equalTo(titleBarView.snp_bottom)
            make.width.equalTo(contentView.frame.width - 20)
            make.height.equalTo(contentView.frame.width / 1.8)
            make.centerX.equalTo(contentView)
        }

        playButton = UIButton()
        playButton.titleLabel?.font = UIFont.fontAwesomeOfSize(75)
        playButton.setTitle(String.fontAwesomeIconWithName(.PlayCircle), forState: .Normal)
        contentView.addSubview(playButton)
        playButton.snp_makeConstraints { (make) in
            make.center.equalTo(imageView)
        }

        videoPlayer = YouTubePlayerView()
        videoPlayer.playerVars = [
            "controls": "1",
            "autoplay": "1",
            "showinfo": "0",
            "autohide":"2",
            "modestbranding":"0",
            "rel":1
        ]
        videoPlayer.contentMode = UIViewContentMode.ScaleAspectFill
        contentView.insertSubview(videoPlayer, belowSubview: imageView)
        videoPlayer.snp_makeConstraints { (make) in
            make.width.equalTo(contentView.frame.width - 40)
            make.height.equalTo(contentView.frame.width / 2)
            make.center.equalTo(imageView)
        }

        barActionView = UIView()
        barActionView.backgroundColor = UIColor.clearColor()
        contentView.addSubview(barActionView)
        barActionView.snp_makeConstraints { (make) in
            make.top.equalTo(imageView.snp_bottom)
            make.width.equalTo(contentView.frame.width - 40)
            make.height.equalTo(44.0)
            make.centerX.equalTo(contentView)
        }

        favoriteBarButton = UIButton()
        favoriteBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.HeartO), forState: .Normal)
        favoriteBarButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        barActionView.addSubview(favoriteBarButton)
        favoriteBarButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(barActionView.leftAnchor)
        }

        shareBarButton = UIButton()
        shareBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        shareBarButton.setTitle(String.fontAwesomeIconWithName(.Share), forState: .Normal)
        shareBarButton.setTitleColor(barButtonColor, forState: .Normal)
        barActionView.addSubview(shareBarButton)
        shareBarButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(favoriteBarButton.snp_right).offset(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
