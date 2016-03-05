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
// https://github.com/gilesvangruisen/Swift-YouTube-Player

let nextPageTokenConstant = "nextPageToken"

class MotivationFeedViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Initialize delegate
        collectionView.delegate = self
        fetchedResultsController.delegate = self

        // Configure CollectionView
        collectionView!.registerClass(youtubeCollectionViewCell.self,forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = UIColor.clearColor()

        let longTap: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "savedItem:")
        longTap.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longTap)

        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refreshData")
        navigationItem.rightBarButtonItem = button

        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }

        view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundFeed.png")!)
    }

    // Initialize CoreData and NSFetchedResultsController

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    func savedItem(gestureRecognizer: UIGestureRecognizer) {
        guard gestureRecognizer.state != .Ended else {
            return
        }

        let tapPoint: CGPoint = gestureRecognizer.locationInView(collectionView)
        let indexPath = collectionView.indexPathForItemAtPoint(tapPoint)

        guard indexPath != nil else {
            return
        }

        let objet = fetchedResultsController.objectAtIndexPath(indexPath!) as! MotivationFeedItem
        objet.saved = true
        CoreDataStackManager.sharedInstance.saveContext()
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "MotivationFeedItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "addedDate", ascending: false)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        return fetchedResultsController
        
    }()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - NSFetchedResultsController related property
    var blockOperations: [NSBlockOperation] = []

    func refreshData() {
        var mutableParameters: [String : AnyObject]

        let parameters: [String : AnyObject] = [
            "part":"snippet",
            "order":"viewCount",
            "q": "motivation+success",
            "type":"video",
            "videoDefinition":"high",
            "maxResults": 10,
            "key":"\(MHClient.Constants.ApiKey!)"
        ]

        mutableParameters = parameters

        let defaults = NSUserDefaults.standardUserDefaults()
        if let nextPageToken = defaults.stringForKey(nextPageTokenConstant)
        {
            mutableParameters["pageToken"] = "\(nextPageToken)"
        }

        MHClient.sharedInstance.taskForResource(mutableParameters) { (result, error) -> Void in
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }

            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(result.objectForKey("nextPageToken") as! String, forKey:nextPageTokenConstant)

            guard let results = result["items"] as? [[String:AnyObject]] else {
                return
            }

            for item in results {
                guard let videoSnippet = item["snippet"] as? [String:AnyObject] else {
                    return
                }
                
                guard let title = videoSnippet["title"] as? String else {
                    return
                }

                guard let description = videoSnippet["description"] as? String else {
                    return
                }
                
                guard let id = item["id"]!["videoId"] as? String else {
                    return
                }

                guard let thumbnailsUrl = videoSnippet["thumbnails"]!["high"]!!["url"] as? String else {
                    return
                }

                let _ = MotivationFeedItem(itemTitle: title, itemDescription: description, itemID: id, itemThumbnailsUrl: thumbnailsUrl, saved: false, addedDate: NSDate(), context: self.sharedContext)
                CoreDataStackManager.sharedInstance.saveContext()
            }
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! youtubeCollectionViewCell

        configureCell(cell, withItem: motivationItem)

        let myVideoID = motivationItem.itemID
        cell.textLabel.text = motivationItem.itemTitle
        cell.videoPlayer.loadVideoID(myVideoID)
        cell.imageView.userInteractionEnabled = false
        cell.videoPlayer.userInteractionEnabled = false
        cell.clipsToBounds = true
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("Touch")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! youtubeCollectionViewCell
        cell.videoPlayer.play()
    }

    func configureCell(cell: youtubeCollectionViewCell, withItem item: MotivationFeedItem) {
        if item.image != nil {
            dispatch_async(dispatch_get_main_queue()) {
                cell.imageView.image = item.image
                UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    cell.alpha = 1.0
                    }, completion: nil)
            }
        } else {
            MHClient.sharedInstance.taskForImage(item.itemThumbnailsUrl) { imageData, error in
                if let image = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        item.image = UIImage(data: image)
                        cell.imageView.image = item.image
                        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                            cell.alpha = 1.0
                            }, completion: nil)
                    }
                }
            }
        }
    }


    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let dimension = view.frame.size.width / 2.0
        return CGSizeMake(dimension, dimension)
    }

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return UIEdgeInsetsZero
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
        }
        else if type == NSFetchedResultsChangeType.Update {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Move {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Delete {
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
        }
        else if type == NSFetchedResultsChangeType.Update {
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Delete {
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