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
        barButtonSize = 35

        titleBarView = UIView()
        contentView.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.top)
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
        contentView.addSubview(barActionView)
        barActionView.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom)
            make.width.equalTo(contentView.frame.width - 40)
            make.height.equalTo(44.0)
            make.centerX.equalTo(contentView)
        }

        favoriteBarButton = UIButton()
        favoriteBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(27)
        favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.HeartO), for: .normal)
        favoriteBarButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: UIControlState())
        barActionView.addSubview(favoriteBarButton)
        favoriteBarButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(barActionView.snp.left)
        }

        shareBarButton = UIButton()
        let shareImage = imageFromSystemBarButton(systemItem: UIBarButtonSystemItem.action).imageWithSize(size: CGSize(width: 18, height: 27))
        shareBarButton.imageView?.contentMode = .scaleAspectFit
        shareBarButton.setImage(shareImage, for: .normal)
        shareBarButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        barActionView.addSubview(shareBarButton)
        shareBarButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.width.equalTo(18)
            make.height.equalTo(27)
            make.left.equalTo(favoriteBarButton.snp.right).offset(15)
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
    
    func imageFromSystemBarButton(systemItem: UIBarButtonSystemItem)-> UIImage {
        let tempItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)
        
        // add to toolbar and render it
        UIToolbar().setItems([tempItem], animated: false)
        
        // got image from real uibutton
        let itemView = tempItem.value(forKey: "view") as! UIView
        for view in itemView.subviews {
            if view.isKind(of: UIButton.self){
                let button = view as! UIButton
                return button.imageView!.image!.withRenderingMode(.alwaysTemplate)
            }
        }
        
        return UIImage()
    }
}
