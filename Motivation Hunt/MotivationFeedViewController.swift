//
//  MotivationFeedViewController.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 23/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import CoreData
import YouTubePlayer
import CloudKit
import Async
import Toucan
import SnapKit
import Alamofire

let nextPageTokenConstant = "nextPageToken"

class MotivationFeedViewController: UIViewController {

    var collectionView: UICollectionView!
    var indicator = CustomUIActivityIndicatorView()
    let refreshCtrl = UIRefreshControl()
    var blockOperations: [NSBlockOperation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        setupUI()

        // Initialize delegate
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }

        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            refreshData()
        }
    }

    // Initialize CoreData and NSFetchedResultsController

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "MotivationFeedItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "addedDate", ascending: false)]

        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        return fetchedResultsController
    }()

    deinit {
        // Cancel all block operations when VC deallocates
        for operation: NSBlockOperation in blockOperations {
            operation.cancel()
        }

        blockOperations.removeAll(keepCapacity: false)
    }
}

extension MotivationFeedViewController {

    override func viewDidLayoutSubviews() {
        if let rectNavigationBar = navigationController?.navigationBar.frame, let rectTabBar = tabBarController?.tabBar.frame  {
            let navigationBarSpace = rectNavigationBar.size.height + rectNavigationBar.origin.y
            let tabBarSpace = rectTabBar.size.height + rectTabBar.origin.x
            collectionView.contentInset = UIEdgeInsetsMake(navigationBarSpace, 0, tabBarSpace, 0)
        }
    }

    func setupUI() {
        // Configure CollectionView
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.registerClass(motivationCollectionViewCell.self, forCellWithReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier)
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.allowsMultipleSelection = false
        view.addSubview(collectionView)
        collectionView.snp_makeConstraints { (make) in
            make.top.equalTo(view)
            make.width.equalTo(view)
            make.bottom.equalTo(view.snp_bottom)
            make.center.equalTo(view)
        }

        refreshCtrl.addTarget(self, action: #selector(MotivationFeedViewController.refreshData), forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshCtrl)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: #selector(refreshData))

        // Set background View
        view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundFeed.png")!)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.insertSubview(blurEffectView, belowSubview: collectionView)
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {}
}

extension MotivationFeedViewController {

    func savedItem(gestureRecognizer: UIGestureRecognizer) {
        let tapPoint: CGPoint = gestureRecognizer.locationInView(collectionView)
        let indexPath = collectionView.indexPathForItemAtPoint(tapPoint)
        let objet = fetchedResultsController.objectAtIndexPath(indexPath!) as! MotivationFeedItem

        Async.main {
            objet.saved = objet.saved ? false : true
            CoreDataStackManager.sharedInstance.saveContext()
        }

        CloudKitHelper.sharedInstance.updateFavorites(CKRecordID(recordName: objet.itemRecordID)) { (success, record, error) in
            guard error == nil else {
                return
            }
        }
    }

    func playVideo(gestureRecognizer: UIGestureRecognizer) {
        let tapPoint: CGPoint = gestureRecognizer.locationInView(collectionView)
        let indexPath = collectionView.indexPathForItemAtPoint(tapPoint)
        let cell = collectionView.cellForItemAtIndexPath(indexPath!) as! motivationCollectionViewCell

        cell.videoPlayer.play()

        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            cell.videoPlayer.alpha = 1
            cell.playButton.alpha = 0
            cell.imageView.alpha = 0
            }, completion: nil)
    }

    func shareMotivation(gestureRecognizer: UIGestureRecognizer) {
        let tapPoint: CGPoint = gestureRecognizer.locationInView(collectionView)
        let indexPath = collectionView.indexPathForItemAtPoint(tapPoint)
        let cell = collectionView.cellForItemAtIndexPath(indexPath!) as! motivationCollectionViewCell
        let motivation = fetchedResultsController.objectAtIndexPath(indexPath!) as! MotivationFeedItem
        let motivationToShare = [motivation.itemTitle, motivation.itemDescription, "\(MHClient.Resources.youtubeBaseUrl)\(motivation.itemID)"]
        let activityViewController = UIActivityViewController(activityItems: motivationToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]

        activityViewController.popoverPresentationController?.sourceView = cell.imageView
        activityViewController.popoverPresentationController?.sourceRect = cell.imageView.bounds

        self.presentViewController(activityViewController, animated: true, completion: nil)
    }

    func refreshData() {
        indicator.startActivity()
        view.addSubview(indicator)
        var mutableParameters: [String : AnyObject]

        let parameters: [String : AnyObject] = [
            MHClient.JSONKeys.part:MHClient.JSONKeys.snippet,
            MHClient.JSONKeys.order:MHClient.JSONKeys.viewCount,
            MHClient.JSONKeys.query: "motivation+success",
            MHClient.JSONKeys.type:MHClient.JSONKeys.videoType,
            MHClient.JSONKeys.videoDefinition:MHClient.JSONKeys.qualityHigh,
            MHClient.JSONKeys.maxResults: 10,
            MHClient.JSONKeys.key:MHClient.Constants.ApiKey!
        ]

        mutableParameters = parameters

        let defaults = NSUserDefaults.standardUserDefaults()
        if let nextPageToken = defaults.stringForKey(nextPageTokenConstant) {
            mutableParameters["pageToken"] = "\(nextPageToken)"
        }
        let request = Alamofire.request(.GET, MHClient.Resources.searchVideos, parameters: parameters)

        // TODO: Use progress

//        request.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
//            Async.main {
//            let progressView = UIProgressView(progressViewStyle: .Bar)
//            progressView.trackTintColor = UIColor.redColor()
//            let percent = (Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
//            Log.info(percent)
//            progressView.setProgress(percent, animated: true)
//            }
//        }
        request.responseJSON { response in
                guard response.result.isSuccess,
                    let results = response.result.value![MHClient.JSONResponseKeys.items] as? [[String:AnyObject]],
                    let nextPageTokenKey = response.result.value!["nextPageToken"] as? String else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.indicator.stopActivity()
                        self.indicator.removeFromSuperview()
                        let errorAlert = UIAlertController(title: "Oops… Unable to load feed", message: response.description, preferredStyle: UIAlertControllerStyle.Alert)
                        errorAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(errorAlert, animated: true, completion: nil)
                    })
                    Log.warning("There was an error with your request: \(response.description)")
                    return
                }

                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(nextPageTokenKey, forKey:nextPageTokenConstant)

                for item in results {
                    guard let snippet = item[MHClient.JSONResponseKeys.snippet] as? [String:AnyObject],
                        let title = snippet[MHClient.JSONResponseKeys.title] as? String,
                        let description = snippet[MHClient.JSONResponseKeys.description] as? String,
                        let id = item[MHClient.JSONResponseKeys.ID]![MHClient.JSONResponseKeys.videoId] as? String,
                        let thumbnailsUrl = snippet[MHClient.JSONResponseKeys.thumbnails]![MHClient.JSONResponseKeys.quality]!![MHClient.JSONResponseKeys.url] as? String
                        else {
                            return
                    }

                    CloudKitHelper.sharedInstance.savedMotivationItem(title, itemDescription: description, itemID: id, itemThumbnailsUrl: thumbnailsUrl, saved: false, addedDate: NSDate()) { (success, record, error) in
                        guard success else {
                            return
                        }

                        Async.main {
                            let _ = MotivationFeedItem(itemTitle: title, itemDescription: description, itemID: id, itemThumbnailsUrl: thumbnailsUrl, saved: false, addedDate: NSDate(), itemRecordID: record.recordID.recordName, theme: "motivation+success", context: self.sharedContext)
                            CoreDataStackManager.sharedInstance.saveContext()
                        }
                    }
                }
        }

        Async.main {
            self.indicator.stopActivity()
            self.indicator.removeFromSuperview()
        }

        if refreshCtrl.refreshing {
            refreshCtrl.endRefreshing()
        }

    }
}

extension MotivationFeedViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let motivationItem = fetchedResultsController.objectAtIndexPath(indexPath) as! MotivationFeedItem
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MHClient.CellIdentifier.cellWithReuseIdentifier, forIndexPath: indexPath) as! motivationCollectionViewCell
        configureCell(cell, withItem: motivationItem)
        return cell
    }

    func configureCell(cell: motivationCollectionViewCell, withItem item: MotivationFeedItem) {
        cell.videoPlayer.delegate = self
        cell.textLabel.text = item.itemTitle

        let playVideoOnTapPlayButton: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(playVideo(_:)))
        playVideoOnTapPlayButton.numberOfTapsRequired = 1
        cell.playButton.addGestureRecognizer(playVideoOnTapPlayButton)

        let playVideoOnTapImageView: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(playVideo(_:)))
        playVideoOnTapImageView.numberOfTapsRequired = 1
        cell.imageView.addGestureRecognizer(playVideoOnTapImageView)

        let tapToSavedItem: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(savedItem(_:)))
        tapToSavedItem.numberOfTapsRequired = 1
        cell.favoriteBarButton.addGestureRecognizer(tapToSavedItem)

        let shareOnTapshareBarButton: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(shareMotivation(_:)))
        shareOnTapshareBarButton.numberOfTapsRequired = 1
        cell.shareBarButton.addGestureRecognizer(shareOnTapshareBarButton)

        if item.saved {
            cell.favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.Heart), forState: .Normal)
        } else {
            cell.favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.HeartO), forState: .Normal)
        }

        if item.image == nil {
            MHClient.sharedInstance.taskForImage(item.itemThumbnailsUrl) { imageData, error in
                guard error == nil else {
                    return
                }
                Async.main {
                    item.image = UIImage(data: imageData!)
                }
            }
        }

        if item.image != nil {
            Async.main {
                cell.imageView.image = Toucan(image: item.image!).resize(CGSize(width: cell.frame.width - 10, height: cell.frame.width / 1.8), fitMode: Toucan.Resize.FitMode.Crop).maskWithRoundedRect(cornerRadius: 10).image
            }
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? motivationCollectionViewCell {
            let motivationItem = fetchedResultsController.objectAtIndexPath(indexPath) as! MotivationFeedItem
            cell.videoPlayer.loadVideoID(motivationItem.itemID)
            cell.imageView.alpha = 0
            cell.playButton.alpha = 0
            cell.videoPlayer.alpha = 0

            UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                cell.imageView.alpha = 1
                cell.playButton.alpha = 0.7
                }, completion: nil)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let device = UIDevice.currentDevice().model
        let dimensioniPhone = view.frame.width
        var cellSize: CGSize = CGSizeMake(dimensioniPhone, dimensioniPhone * 0.8)
        let dimensioniPad = (view.frame.width / 2) - 15

        if (device == "iPad" || device == "iPad Simulator") {
            cellSize = CGSizeMake(dimensioniPad, dimensioniPad * 0.8)
        }

        return cellSize
    }

    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let device = UIDevice.currentDevice().model
        var edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        if (device == "iPad" || device == "iPad Simulator") {
            edgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }

        return edgeInsets
    }

    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? motivationCollectionViewCell {
            UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                cell.playButton.alpha = 0
                cell.imageView.alpha = 0
                }, completion: nil)
            cell.videoPlayer.stop()
        }
    }
}

extension MotivationFeedViewController: YouTubePlayerDelegate {

    func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        if playerState == .Buffering {
            Async.main {
                self.indicator.startActivity()
                self.view.addSubview(self.indicator)
            }
        }

        if playerState == .Playing {
            Async.main {
                self.indicator.stopActivity()
                self.indicator.removeFromSuperview()
            }
        }

        if playerState == .Paused {
            Async.main {
                self.indicator.stopActivity()
                self.indicator.removeFromSuperview()
            }
        }

        if playerState == .Unstarted {
            Async.main {
                self.indicator.stopActivity()
                self.indicator.removeFromSuperview()
            }
        }
    }
}

extension MotivationFeedViewController: NSFetchedResultsControllerDelegate {
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                    }
                    })
            )
        case .Update:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        case .Move:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch (type) {
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        case .Update:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        case .Move:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveSection(sectionIndex, toSection: sectionIndex)
                    }
                    })
            )
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: NSBlockOperation in self.blockOperations {
                operation.start()
            }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepCapacity: false)
        })
    }
}
