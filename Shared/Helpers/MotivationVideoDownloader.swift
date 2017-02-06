//
//  MotivationVideoDownloader.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 03/02/2017.
//  Copyright © 2017 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import Alamofire

class MotivationVideoDownloader: NSObject {

    private let iCloudKeyStore: NSUbiquitousKeyValueStore? = NSUbiquitousKeyValueStore()
    
    func downloadNewItemVideo(theme: Theme, completionHandler: @escaping (_ success: Bool, _ motivationVideoItem: [[String : Any]]?) -> Void) {
        
        let themeToSearch = youtubeMotivationQuery(for: theme)
        var motivationVideos: [[String : Any]] = []
        
        let youtubeHeaderParameters: [String : AnyObject] = [
            MHClient.JSONKeys.part: MHClient.JSONKeys.snippet as AnyObject,
            MHClient.JSONKeys.order: MHClient.JSONKeys.relevance as AnyObject,
            MHClient.JSONKeys.query: themeToSearch as AnyObject,
            MHClient.JSONKeys.type: MHClient.JSONKeys.videoType as AnyObject,
            MHClient.JSONKeys.videoDefinition: MHClient.JSONKeys.qualityHigh as AnyObject,
            MHClient.JSONKeys.maxResults: 10 as AnyObject,
            MHClient.JSONKeys.key: MHClient.Constants.ApiKey as AnyObject
        ]
        var mutatedYoutubeHeaderParameters: [String : AnyObject] = [:]
        mutatedYoutubeHeaderParameters = youtubeHeaderParameters
        
        if let nextPageToken = iCloudKeyStore?.string(forKey: "nextPageTokenConstant\(theme)") {
            mutatedYoutubeHeaderParameters["pageToken"] = "\(nextPageToken)" as AnyObject?
        }
        
        let request = Alamofire.request(MHClient.Resources.searchVideos, method: .get, parameters: mutatedYoutubeHeaderParameters)
        
        request.responseJSON { response in
            guard response.result.isSuccess else {
                return completionHandler(false, nil)
            }
            
            let results = response.result.value as! [String:AnyObject]
            let videos = results[MHClient.JSONResponseKeys.items] as! [[String:AnyObject]]
            let nextPageKey = results["nextPageToken"] as! String
            
            self.synciCloud(for: nextPageKey, with: theme)
            
            for video in videos {
                
                guard let ID = video[MHClient.JSONResponseKeys.ID] as? [String:AnyObject],
                    let videoID = ID[MHClient.JSONResponseKeys.videoId] as? String,
                    let snippet = video[MHClient.JSONResponseKeys.snippet] as? [String:AnyObject],
                    let title = snippet[MHClient.JSONResponseKeys.title] as? String,
                    let description = snippet[MHClient.JSONResponseKeys.description] as? String
                    else {
                        completionHandler(true, motivationVideos)
                        return
                }
                
                let video: [String : Any] = [
                    "itemVideoID": videoID,
                    "itemTitle": title,
                    "itemDescription": description,
                    "itemThumbnailsUrl": "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg",
                    "saved": false,
                    "theme": theme.rawValue
                ]
                motivationVideos.append(video)
            }
            
            completionHandler(true, motivationVideos)
        }
    }
    
    private func youtubeMotivationQuery(for theme: Theme) -> String {
        switch theme as Theme {
        case .Love:
            return "motivation+human+\(theme.rawValue)"
        case .Money:
            return "motivation+rich+\(theme.rawValue)"
        case .Success:
            return "motivation+\(theme.rawValue)"
        case .All:
            return ""
        }
    }
    
    private func synciCloud(for key: String, with theme: Theme) {
        iCloudKeyStore?.set(key, forKey: "nextPageTokenConstant\(theme)")
        iCloudKeyStore?.synchronize()
    }
}
