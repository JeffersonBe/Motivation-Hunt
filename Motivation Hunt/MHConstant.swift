//
//  MHConstant.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 03/03/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation

extension MHClient {

    struct Constants {
        static let ApiKey = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Key", ofType: "plist")!)?.valueForKey("API_KEY")
        static let BaseUrl = "https://developers.google.com/apis-explorer/#p/youtube/v3/youtube"
    }

    struct Resources {
        static let searchVideos = "https://www.googleapis.com/youtube/v3/search";
    }

    struct Keys {
        static let ID = "id"
        static let ErrorStatusMessage = "status_message"
        static let Extras = "url_m"
        static let Format = "json"
        static let No_json_Callback = "1"
    }

    struct JSONKeys {
        static let Id = "id"
        static let Title = "title"
        static let imageUrl = "url_m"
    }

    struct AppCopy {
        static let deleteSelectedPictures = "Delete Selected Pictures"
        static let newCollection = "New Collection"
        static let noPhotosFoundInCollection = "No photos found for this location"
    }

    struct CellIdentifier {
        static let CollectionViewCellWithReuseIdentifier = "CollectionViewCell"
    }
}