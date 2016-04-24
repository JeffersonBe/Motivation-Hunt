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

let nextPageTokenConstant = "nextPageToken"

class MotivationFeedViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var indicator = CustomUIActivityIndicatorView()
    let refreshCtrl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Initialize delegate
        collectionView.delegate = self
        fetchedResultsController.delegate = self

        // Configure CollectionView
        collectionView!.registerClass(motivationCollectionViewCell.self, forCellWithReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier)
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.allowsMultipleSelection = false

        refreshCtrl.addTarget(self, action: #selector(MotivationFeedViewController.refreshData), forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshCtrl)

        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: #selector(refreshData))
        navigationItem.rightBarButtonItem = button

        // Set background View
        view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundFeed.png")!)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.insertSubview(blurEffectView, belowSubview: collectionView)

        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }

        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            CloudKitHelper.sharedInstance.fetchMotivationFeedItem { (success, record, error) in
                guard error == nil else {
                    return
                }
                Async.main() {
                    CoreDataStackManager.sharedInstance.managedObjectContext.performBlock({
                        for item in record! {
                            let _ = MotivationFeedItem(itemTitle: item.valueForKey("itemTitle") as! String,
                                itemDescription: item.valueForKey("itemDescription") as! String,
                                itemID: item.valueForKey("itemID") as! String,
                                itemThumbnailsUrl: item.valueForKey("itemThumbnailsUrl") as! String,
                                saved: item.valueForKey("saved") as! Bool,
                                addedDate: item.valueForKey("addedDate") as! NSDate,
                                itemRecordID: item.recordID.recordName,
                                context: self.sharedContext)
                            CoreDataStackManager.sharedInstance.saveContext()
                        }
                    })
                }
            }
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

    // MARK: - NSFetchedResultsController related property
    var blockOperations: [NSBlockOperation] = []

    func savedItem(gestureRecognizer: UIGestureRecognizer) {
        let tapPoint: CGPoint = gestureRecognizer.locationInView(collectionView)
        let indexPath = collectionView.indexPathForItemAtPoint(tapPoint)
        let objet = fetchedResultsController.objectAtIndexPath(indexPath!) as! MotivationFeedItem

        CloudKitHelper.sharedInstance.updateFavorites(CKRecordID(recordName: objet.itemRecordID)) { (success, record, error) in
            guard error == nil else {
                return
            }

            Async.main {
                objet.saved = objet.saved ? false : true
                CoreDataStackManager.sharedInstance.saveContext()
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

        Async.background {
            MHClient.sharedInstance.taskForResource(mutableParameters) { (result, error) -> Void in
                guard (error == nil) else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.indicator.stopActivity()
                        self.indicator.removeFromSuperview()
                        let errorAlert = UIAlertController(title: "Oops… Unable to load feed", message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                        errorAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(errorAlert, animated: true, completion: nil)
                    })
                    print("There was an error with your request: \(error)")
                    return
                }

                Async.main {
                    self.indicator.stopActivity()
                    self.indicator.removeFromSuperview()
                }

                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(result["nextPageToken"] as! String, forKey:nextPageTokenConstant)

                guard let results = result[MHClient.JSONResponseKeys.items] as? [[String:AnyObject]] else {
                    return
                }

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
                            let _ = MotivationFeedItem(itemTitle: title, itemDescription: description, itemID: id, itemThumbnailsUrl: thumbnailsUrl, saved: false, addedDate: NSDate(), itemRecordID: record.recordID.recordName, context: self.sharedContext)
                            CoreDataStackManager.sharedInstance.saveContext()
                        }
                    }
                }
            }
        }

        if refreshCtrl.refreshing {
            refreshCtrl.endRefreshing()
        }
    }

    deinit {
        // Cancel all block operations when VC deallocates
        for operation: NSBlockOperation in blockOperations {
            operation.cancel()
        }

        blockOperations.removeAll(keepCapacity: false)

        // Deinitialise Listener
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

extension MotivationFeedViewController: UICollectionViewDelegate {

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
        cell.videoPlayer.loadVideoID(item.itemID)
        cell.imageView.alpha = 0
        cell.playButton.alpha = 0
        cell.videoPlayer.alpha = 0

        let playVideoOnTapPlayButton: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(playVideo(_:)))
        playVideoOnTapPlayButton.numberOfTapsRequired = 1
        cell.playButton.addGestureRecognizer(playVideoOnTapPlayButton)

        let playVideoOnTapImageView: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(playVideo(_:)))
        playVideoOnTapImageView.numberOfTapsRequired = 1
        cell.imageView.addGestureRecognizer(playVideoOnTapImageView)

        let tapToSavedItem: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(savedItem(_:)))
        tapToSavedItem.numberOfTapsRequired = 1
        cell.favoriteBarButton.addGestureRecognizer(tapToSavedItem)

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

        Async.main {
            cell.imageView.image = Toucan(image: item.image!).resize(CGSize(width: cell.frame.width - 10, height: cell.frame.width / 1.8), fitMode: Toucan.Resize.FitMode.Crop).maskWithRoundedRect(cornerRadius: 10).image
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
    // MARK: NSFetchedResultsController delegate
    // Used GIST: https://gist.github.com/AppsTitude/ce072627c61ea3999b8d#file-uicollection-and-nsfetchedresultscontrollerdelegate-integration-swift-L78

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        if type == NSFetchedResultsChangeType.Insert {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                    }
                    })
            )
        } else if type == NSFetchedResultsChangeType.Update {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        } else if type == NSFetchedResultsChangeType.Move {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        } else if type == NSFetchedResultsChangeType.Delete {
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

        if type == NSFetchedResultsChangeType.Insert {

            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        } else if type == NSFetchedResultsChangeType.Update {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        } else if type == NSFetchedResultsChangeType.Delete {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
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
