//
//  youtubeCollectionViewCell.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 27/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import YouTubePlayer
import SnapKit
import FontAwesome

class youtubeCollectionViewCell: UICollectionViewCell {
    var videoPlayer: YouTubePlayerView!

    var titleBarView: UIView!
    var textLabel: UILabel!
    var imageView: UIImageView!

    var playButton: UIButton!

    var barActionView: UIView!
    var favoriteBarButton: UIButton!

    var shareBarButton: UIButton!

    var youtubeBarButton: UIButton!

    var barButtonColor: UIColor!
    var barButtonSize: CGFloat!

    override init(frame: CGRect) {
        super.init(frame: frame)

        barButtonColor = UIColor.grayColor()
        barButtonSize = 25.00

        titleBarView = UIView()
        titleBarView.backgroundColor = UIColor.blackColor()
        contentView.addSubview(titleBarView)
        titleBarView.snp_makeConstraints { (make) in
            make.top.equalTo(contentView.snp_top)
            make.width.equalTo(contentView)
            make.height.equalTo(66.0)
        }

        textLabel = UILabel()
        textLabel.textColor = UIColor.whiteColor()
        textLabel.textAlignment = .Center
        titleBarView.addSubview(textLabel)
        textLabel.snp_makeConstraints { (make) in
            make.width.equalTo(titleBarView)
            make.centerY.equalTo(titleBarView)
        }

        imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        contentView.insertSubview(imageView, belowSubview: titleBarView)
        imageView.snp_makeConstraints { (make) in
            make.top.equalTo(titleBarView.snp_bottom).inset(40)
            make.width.equalTo(contentView.frame.width)
            make.height.equalTo(contentView.frame.width / 1.3)
        }

        videoPlayer = YouTubePlayerView()
        videoPlayer.contentMode = UIViewContentMode.ScaleAspectFill
        contentView.insertSubview(videoPlayer, belowSubview: imageView)
        videoPlayer.snp_makeConstraints { (make) in
            make.top.equalTo(imageView.snp_top)
            make.width.equalTo(contentView.frame.width)
            make.height.equalTo(contentView.frame.width / 1.3)
        }
        
        barActionView = UIView()
        barActionView.backgroundColor = UIColor.blackColor()
        contentView.insertSubview(barActionView, aboveSubview: imageView)
        barActionView.snp_makeConstraints { (make) in
            make.top.equalTo(imageView.snp_bottom).inset(40)
            make.width.equalTo(contentView)
            make.height.equalTo(66.0)
        }

        favoriteBarButton = UIButton()
        favoriteBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.Heart), forState: .Normal)
        favoriteBarButton.setTitleColor(barButtonColor, forState: .Normal)
        barActionView.addSubview(favoriteBarButton)
        favoriteBarButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(barActionView.leftAnchor).offset(10)
        }

        shareBarButton = UIButton()
        shareBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        shareBarButton.setTitle(String.fontAwesomeIconWithName(.Share), forState: .Normal)
        shareBarButton.setTitleColor(barButtonColor, forState: .Normal)
        barActionView.addSubview(shareBarButton)
        shareBarButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(favoriteBarButton.snp_right).offset(10)
        }

        youtubeBarButton = UIButton()
        youtubeBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        youtubeBarButton.setTitle(String.fontAwesomeIconWithName(.YouTube), forState: .Normal)
        youtubeBarButton.setTitleColor(barButtonColor, forState: .Normal)
        barActionView.addSubview(youtubeBarButton)
        youtubeBarButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(shareBarButton.snp_right).offset(10)
        }

        playButton = UIButton()
        playButton.titleLabel?.font = UIFont.fontAwesomeOfSize(75)
        playButton.setTitle(String.fontAwesomeIconWithName(.PlayCircle), forState: .Normal)
        playButton.alpha = 0.7
        contentView.insertSubview(playButton, aboveSubview: imageView)
        playButton.snp_makeConstraints { (make) in
            make.center.equalTo(imageView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
