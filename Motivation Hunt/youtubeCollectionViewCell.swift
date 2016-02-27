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

    override init(frame: CGRect) {
        super.init(frame: frame)
        videoPlayer = YouTubePlayerView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        videoPlayer.contentMode = UIViewContentMode.ScaleAspectFit
        contentView.addSubview(videoPlayer)

        textLabel = UILabel(frame: CGRect(x: 0, y: videoPlayer.frame.size.height, width: frame.size.width, height: frame.size.height/3))
        textLabel.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
        textLabel.textAlignment = .Center
        contentView.addSubview(textLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
