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
        static let CKBaseUrl = "iCloud.com.jeffersonbonnaire.motivationhunt"
        static let StoreName = "MotivationHunt"
    }

    struct Resources {
        static let searchVideos = "https://www.googleapis.com/youtube/v3/search"
        static let youtubeBaseUrl = "https://www.youtube.com/watch?v="
    }

    struct Keys {
        static let ID = "id"
        static let ErrorStatusMessage = "status_message"
        static let Extras = "url_m"
        static let Format = "json"
        static let No_json_Callback = "1"
    }

    struct JSONKeys {
        static let part = "part"
        static let snippet = "snippet"
        static let order = "order"
        static let viewCount = "viewCount"
        static let query = "q"
        static let type = "type"
        static let videoType = "video"
        static let videoDefinition = "videoDefinition"
        static let qualityHigh = "high"
        static let maxResults = "maxResults"
        static let key = "key"
    }

    struct JSONResponseKeys {
        static let items = "items"
        static let ID = "id"
        static let snippet = "snippet"
        static let title = "title"
        static let description = "description"
        static let videoId = "videoId"
        static let thumbnails = "thumbnails"
        static let quality = "high"
        static let url = "url"
    }

    struct AppCopy {
        static let unableToLoadVideo = "Oops… Unable to load the video"
        static let noInternetConnection = "You don't have any internet connection :-("
        static let dismiss = "Dismiss"
        static let completeBy = "Complete by:"
        static let completedBy = "Completed by:"
        static let delete = "Delete"
        static let unComplete = "Uncompleted"
        static let complete = "Complete"
        static let addChallenge = "Add a challenge"
        static let pleaseAddAChallenge = "Please add a challenge"
        static let icloudAccountTitleError = "Please add an iCloud Account"
        static let icloudAccountMessageError = "To use Motivation Hunt, you need to add an iCloud account"
        
    }

    struct CellIdentifier {
        static let cellWithReuseIdentifier = "Cell"
    }
}
