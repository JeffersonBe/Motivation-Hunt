//
//  SavedMotivationItemViewController.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 27/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import CoreData
import YouTubePlayer

class SavedMotivationItemViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var indicator = CustomUIActivityIndicatorView()
    var currentFavoriteindexPath: NSIndexPath!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize delegate
        collectionView.delegate = self
        fetchedResultsController.delegate = self

        // Configure CollectionView
        collectionView!.registerClass(youtubeCollectionViewCell.self,forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.allowsMultipleSelection = false

        let longTap: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "savedItem:")
        longTap.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longTap)

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Initialize CoreData and NSFetchedResultsController

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "MotivationFeedItem")
        let predicate = NSPredicate(format: "saved == 1")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "itemID", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        return fetchedResultsController
    }()

    // MARK: - NSFetchedResultsController related property
    var blockOperations: [NSBlockOperation] = []

    func savedItem(gestureRecognizer: UIGestureRecognizer) {

        guard gestureRecognizer.state != .Ended else {
            return
        }

        // Check if collectionViewCell are already open, then close it
        let visibleCell = collectionView.visibleCells()
        for cell in visibleCell {
            let selectedNSIndexPath = collectionView.indexPathForCell(cell)
            if selectedNSIndexPath == currentFavoriteindexPath {
                hideFavoritesMenu()
            }
        }

        // Reinitialise currentFavoriteindexPath to new collectionViewCell touched
        let tapPoint: CGPoint = gestureRecognizer.locationInView(collectionView)
        let indexPath = collectionView.indexPathForItemAtPoint(tapPoint)
        currentFavoriteindexPath = indexPath

        let cell = collectionView.cellForItemAtIndexPath(currentFavoriteindexPath) as! youtubeCollectionViewCell
        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideFavoritesMenu")
        tapRecognizer.numberOfTapsRequired = 1
        cell.blurEffectView.addGestureRecognizer(tapRecognizer)

        guard indexPath != nil else {
            return
        }
        showFavoritesMenu()
    }

    func buttonAction(sender:UIButton!) {
        // http://stackoverflow.com/questions/27429652/detecting-uibutton-pressed-in-tableview-swift-best-practices
        let objet = fetchedResultsController.objectAtIndexPath(currentFavoriteindexPath!) as! MotivationFeedItem
        if objet.saved {
            CoreDataStackManager.sharedInstance.managedObjectContext.performBlock() {
                objet.saved = false
                CoreDataStackManager.sharedInstance.saveContext()
            }
            hideFavoritesMenu()
        } else {
            CoreDataStackManager.sharedInstance.managedObjectContext.performBlock() {
                objet.saved = true
                CoreDataStackManager.sharedInstance.saveContext()
            }
            hideFavoritesMenu()
        }
    }

    func showFavoritesMenu(){
        let cell = collectionView.cellForItemAtIndexPath(currentFavoriteindexPath) as! youtubeCollectionViewCell
        let objet = fetchedResultsController.objectAtIndexPath(currentFavoriteindexPath!) as! MotivationFeedItem

        if objet.saved {
            cell.favoriteButton.setImage(UIImage(named: "iconSelectedFeatured") as UIImage?, forState: .Normal)
        }

        cell.favoriteButton.hidden = false
        cell.blurEffectView.hidden = false
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            cell.favoriteButton.alpha = 1.0
            }, completion: nil)
    }

    func hideFavoritesMenu() {
        let cell = collectionView.cellForItemAtIndexPath(currentFavoriteindexPath) as! youtubeCollectionViewCell

        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            cell.favoriteButton.alpha = 0
            }, completion: nil)
        cell.favoriteButton.hidden = true
        cell.blurEffectView.hidden = true
    }
}

extension SavedMotivationItemViewController: UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let motivationItem = fetchedResultsController.objectAtIndexPath(indexPath) as! MotivationFeedItem
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! youtubeCollectionViewCell
        configureCell(cell, withItem: motivationItem)
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! youtubeCollectionViewCell
        if Reachability.connectedToNetwork() {
            cell.videoPlayer.play()
        } else {
            let errorAlert = UIAlertController(title: "Ops… Unable to load the video", message: "You don't have an internet connection :-(", preferredStyle: UIAlertControllerStyle.Alert)
            errorAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
            presentViewController(errorAlert, animated: true, completion: nil)
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

    func configureCell(cell: youtubeCollectionViewCell, withItem item: MotivationFeedItem) {
        cell.videoPlayer.delegate = self
        cell.textLabel.text = item.itemTitle
        cell.videoPlayer.loadVideoID(item.itemID)
        cell.favoriteButton.hidden = true
        cell.favoriteButton.addTarget(self, action: "buttonAction:", forControlEvents:
            UIControlEvents.TouchUpInside)
        cell.blurEffectView.hidden = true
        cell.videoPlayer.userInteractionEnabled = false
        cell.imageView.userInteractionEnabled = false
        cell.clipsToBounds = true

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
}

extension SavedMotivationItemViewController: YouTubePlayerDelegate {
    func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        if playerState == .Buffering {
            indicator.startActivity()
            view.addSubview(indicator)
        }

        if playerState == .Playing {
            indicator.stopActivity()
            indicator.removeFromSuperview()
        }
    }

    func playerQualityChanged(videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {}
    func playerReady(videoPlayer: YouTubePlayerView) {}
}


extension SavedMotivationItemViewController: NSFetchedResultsControllerDelegate {
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
