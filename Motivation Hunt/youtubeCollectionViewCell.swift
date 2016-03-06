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
}
