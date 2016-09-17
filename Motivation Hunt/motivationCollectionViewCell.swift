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

        barButtonColor = UIColor.gray
        barButtonSize = 25.00

        titleBarView = UIView()
        titleBarView.backgroundColor = UIColor.clear
        contentView.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.top)
            make.width.equalTo(contentView.frame.width - 20)
            make.height.equalTo(44)
            make.centerX.equalTo(contentView)
        }

        textLabel = UILabel()
        textLabel.textColor = UIColor.white
        textLabel.textAlignment = .center
        titleBarView.addSubview(textLabel)
        textLabel.snp.makeConstraints { (make) in
            make.width.equalTo(titleBarView)
            make.center.equalTo(titleBarView)
        }

        imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        contentView.addSubview(imageView)
        addParallaxToView(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(titleBarView.snp.bottom)
            make.width.equalTo(contentView.frame.width - 20)
            make.height.equalTo(contentView.frame.width / 1.8)
            make.centerX.equalTo(contentView)
        }

        playButton = UIButton()
        playButton.titleLabel?.font = UIFont.fontAwesomeOfSize(75)
        playButton.setTitle(String.fontAwesomeIconWithName(.PlayCircle), for: .normal)
        contentView.addSubview(playButton)
        playButton.snp.makeConstraints { (make) in
            make.center.equalTo(imageView)
        }

        videoPlayer = YouTubePlayerView()
        videoPlayer.playerVars = [
            "controls": "1" as AnyObject,
            "autoplay": "1" as AnyObject,
            "showinfo": "0" as AnyObject,
            "autohide":"2" as AnyObject,
            "modestbranding":"0" as AnyObject,
            "rel":1 as AnyObject
        ]
        videoPlayer.contentMode = UIViewContentMode.scaleAspectFill
        contentView.insertSubview(videoPlayer, belowSubview: imageView)
        videoPlayer.snp.makeConstraints { (make) in
            make.width.equalTo(contentView.frame.width - 40)
            make.height.equalTo(contentView.frame.width / 2)
            make.center.equalTo(imageView)
        }

        barActionView = UIView()
        barActionView.backgroundColor = UIColor.clear
        contentView.addSubview(barActionView)
        barActionView.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom)
            make.width.equalTo(contentView.frame.width - 40)
            make.height.equalTo(44.0)
            make.centerX.equalTo(contentView)
        }

        favoriteBarButton = UIButton()
        favoriteBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.HeartO), for: .normal)
        favoriteBarButton.setTitleColor(UIColor.white, for: UIControlState())
        barActionView.addSubview(favoriteBarButton)
        favoriteBarButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(barActionView.snp.left)
        }

        shareBarButton = UIButton()
        shareBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        shareBarButton.setTitle(String.fontAwesomeIconWithName(.Share), for: .normal)
        shareBarButton.setTitleColor(barButtonColor, for: UIControlState())
        barActionView.addSubview(shareBarButton)
        shareBarButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(favoriteBarButton.snp.right).offset(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func addParallaxToView(_ vw: UIView) {
        let amount = 15

        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        vw.addMotionEffect(group)
    }
}
