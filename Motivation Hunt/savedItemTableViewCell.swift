//
//  savedItemTableViewCell.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 05/03/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import YouTubePlayer

class savedItemTableViewCell: UITableViewCell {

    @IBOutlet weak var savedItemTextLabel: UILabel!
    @IBOutlet weak var savedItemImageView: UIImageView!
    @IBOutlet weak var customView: UIView!
    var videoPlayer: YouTubePlayerView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // http://stackoverflow.com/a/33476294/2629814
        videoPlayer = YouTubePlayerView(frame: customView.frame)
        videoPlayer.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        contentView.insertSubview(videoPlayer, belowSubview: savedItemImageView)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
