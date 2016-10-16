//
//  motivationCollectionViewCell.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 19/04/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import SnapKit
import FontAwesome
import YouTubePlayer

class motivationCollectionViewCell: UICollectionViewCell {
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

        barButtonColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        barButtonSize = 25.00

        titleBarView = UIView()
        titleBarView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        contentView.addSubview(titleBarView)
        titleBarView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.top)
            make.width.equalTo(contentView)
            make.height.equalTo(66.0)
        }

        textLabel = UILabel()
        textLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        textLabel.textAlignment = .center
        titleBarView.addSubview(textLabel)
        textLabel.snp.makeConstraints { (make) in
            make.width.equalTo(titleBarView)
            make.centerY.equalTo(titleBarView)
        }

        imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        contentView.insertSubview(imageView, belowSubview: titleBarView)
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(titleBarView.snp.bottom).inset(40)
            make.width.equalTo(contentView.frame.width)
            make.height.equalTo(contentView.frame.width / 1.3)
        }

        videoPlayer = YouTubePlayerView()
        videoPlayer.contentMode = UIViewContentMode.scaleAspectFill
        contentView.insertSubview(videoPlayer, belowSubview: imageView)
        videoPlayer.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.top)
            make.width.equalTo(contentView.frame.width)
            make.height.equalTo(contentView.frame.width / 1.3)
        }

        barActionView = UIView()
        barActionView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        contentView.insertSubview(barActionView, aboveSubview: imageView)
        barActionView.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).inset(40)
            make.width.equalTo(contentView)
            make.height.equalTo(66.0)
        }

        favoriteBarButton = UIButton()
        favoriteBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.Heart), for: .normal)
        favoriteBarButton.setTitleColor(barButtonColor, for: .normal)
        barActionView.addSubview(favoriteBarButton)
        favoriteBarButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(barActionView.leftAnchor as! ConstraintRelatableTarget).offset(10)
        }

        shareBarButton = UIButton()
//        shareBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
//        shareBarButton.setTitle(String.fontAwesomeIconWithName(.Share), for: .normal)
//        shareBarButton.setTitleColor(barButtonColor, for: .normal)
        shareBarButton.setImage(imageFromSystemBarButton(systemItem: UIBarButtonSystemItem.action), for: .normal)
        shareBarButton.tintColor = barButtonColor
        barActionView.addSubview(shareBarButton)
        shareBarButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(favoriteBarButton.snp.right).offset(10)
        }

        youtubeBarButton = UIButton()
        youtubeBarButton.titleLabel?.font = UIFont.fontAwesomeOfSize(barButtonSize)
        youtubeBarButton.setTitle(String.fontAwesomeIconWithName(.YouTube), for: .normal)
        youtubeBarButton.setTitleColor(barButtonColor, for: .normal)
        barActionView.addSubview(youtubeBarButton)
        youtubeBarButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(barActionView)
            make.left.equalTo(shareBarButton.snp.right).offset(10)
        }

        playButton = UIButton()
        playButton.titleLabel?.font = UIFont.fontAwesomeOfSize(75)
        playButton.setTitle(String.fontAwesomeIconWithName(.PlayCircle), for: .normal)
        playButton.alpha = 0.7
        contentView.insertSubview(playButton, aboveSubview: imageView)
        playButton.snp.makeConstraints { (make) in
            make.center.equalTo(imageView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
                return button.imageView!.image!
            }
        }
        
        return UIImage()
    }
}
