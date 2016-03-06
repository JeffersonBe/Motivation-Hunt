//
//  youtubeCollectionViewCell.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 27/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import YouTubePlayer

class youtubeCollectionViewCell: UICollectionViewCell {
    var videoPlayer: YouTubePlayerView!
    var textLabel: UILabel!
    var imageView: UIImageView!
    var favoriteButton: UIButton!
    var blurEffectView: UIVisualEffectView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        videoPlayer = YouTubePlayerView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        videoPlayer.contentMode = UIViewContentMode.ScaleAspectFill
        contentView.addSubview(videoPlayer)

        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        contentView.addSubview(imageView)

        textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height/3))
        textLabel.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
        textLabel.textColor = UIColor.whiteColor()
        textLabel.textAlignment = .Center
        contentView.addSubview(textLabel)

        let image = UIImage(named: "iconFeatured") as UIImage?
        favoriteButton = UIButton(type: UIButtonType.System) as UIButton
        favoriteButton.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.width/2)
        favoriteButton.imageView?.clipsToBounds = true
        favoriteButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        favoriteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
        favoriteButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        favoriteButton.contentEdgeInsets = UIEdgeInsetsMake(10, 15, 10, 15)
        favoriteButton.setImage(image, forState: .Normal)
        // http://stackoverflow.com/questions/32219161/set-the-center-of-a-uibutton-programmatically-swift
        favoriteButton.center = imageView.center
        contentView.addSubview(favoriteButton)

        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = contentView.frame
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        contentView.insertSubview(blurEffectView, belowSubview: favoriteButton)

        let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurView = UIVisualEffectView(effect: darkBlur)
        blurView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height/3)
        contentView.insertSubview(blurView, belowSubview: textLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    override var selected: Bool {
        didSet {
            if self.selected {
                // do something
                print("selected")
            }
        }
    }
}
