//
//  FavouritesViewController.swift
//  Motivation Hunt TV
//
//  Created by Jefferson Bonnaire on 12/04/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import SnapKit
import CloudKit
import CoreData
import Toucan
import XCDYouTubeKit
import AVKit

class FavouritesViewController: UIViewController {
    
    var collectionView: UICollectionView!
    let originalCellWidth: CGFloat = 500
    var originalCellHeight: CGFloat!
    var originalCellSize: CGSize!
    let focusValue: CGFloat = 1.15
    let playerViewController = AVPlayerViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    // Initialize CoreData and NSFetchedResultsController
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.shared.persistentContainer.viewContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController<VideoItem> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VideoItem") 
        let predicate = NSPredicate(format: "saved == 1")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "addedDate", ascending: false)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.persistentContainer.viewContext, sectionNameKeyPath    : nil, cacheName: nil)
        return fetchedResultsController as! NSFetchedResultsController<VideoItem>
    }()
    
    // MARK: - NSFetchedResultsController related property
    var blockOperations: [BlockOperation] = []
    
    deinit {
        // Cancel all block operations when VC deallocates
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        
        blockOperations.removeAll(keepingCapacity: false)
        
        // Deinitialise Listener
        NotificationCenter.default.removeObserver(self)
    }
}

extension FavouritesViewController {
    func setupUI() {
        // Configure original and Focus CellSize
        originalCellHeight = ((originalCellWidth / 16) * 9) // Keep 16:9 ratio
        originalCellSize = CGSize(width: originalCellWidth, height: originalCellHeight + 44)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 75, bottom: 0, right: 75)
        layout.itemSize = originalCellSize
        layout.minimumInteritemSpacing = CGFloat(50)
        layout.minimumLineSpacing = CGFloat(50)
        layout.scrollDirection = .vertical
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.register(MotivationCollectionViewCell.self, forCellWithReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isScrollEnabled = true
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }
}

extension FavouritesViewController  {
    struct YouTubeVideoQuality {
        static let hd720 = NSNumber(value: XCDYouTubeVideoQuality.HD720.rawValue)
        static let medium360 = NSNumber(value: XCDYouTubeVideoQuality.medium360.rawValue)
        static let small240 = NSNumber(value: XCDYouTubeVideoQuality.small240.rawValue)
    }
    
    func playVideo(withIdentifier Identifier: String?) {
        present(playerViewController, animated: true, completion: nil)
        
        XCDYouTubeClient.default().getVideoWithIdentifier(Identifier) { (video: XCDYouTubeVideo?, error: Error?) in
            guard let streamURLs = video?.streamURLs, let streamURL = (streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?? streamURLs[YouTubeVideoQuality.hd720] ?? streamURLs[YouTubeVideoQuality.medium360] ?? streamURLs[YouTubeVideoQuality.small240]) else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            self.playerViewController.player = AVPlayer(url: streamURL)
            
            if self.playerViewController.player?.currentItem != nil {
                self.playerViewController.player!.play()
            }
        }
    }
}

extension FavouritesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let motivationItem = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier, for: indexPath) as! MotivationCollectionViewCell
        cell.textLabel.text = motivationItem.itemTitle
        
        if motivationItem.image == nil {
            _ = MHClient.sharedInstance.taskForImage(motivationItem.itemThumbnailsUrl) { imageData, error in
                guard error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    motivationItem.image = UIImage(data: imageData!)
                    cell.imageView.image = Toucan(image: motivationItem.image!).resize(CGSize(width: cell.frame.width, height: cell.frame.width / 1.8), fitMode: Toucan.Resize.FitMode.crop).maskWithRoundedRect(cornerRadius: 10).image
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? MotivationCollectionViewCell {
            let motivationItem = fetchedResultsController.object(at: indexPath)
            cell.imageView.alpha = 0
            
            if motivationItem.image != nil {
                DispatchQueue.main.async {
                    cell.imageView.image = Toucan(image: motivationItem.image!).resize(CGSize(width: cell.frame.width, height: cell.frame.width / 1.8), fitMode: Toucan.Resize.FitMode.crop).maskWithRoundedRect(cornerRadius: 10).image
                }
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                cell.imageView.alpha = 1
            }, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let motivationItem = fetchedResultsController.object(at: indexPath)
        playVideo(withIdentifier: motivationItem.itemVideoID)
        collectionView.deselectItem(at: indexPath, animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        guard let indexPaths = collectionView.indexPathsForSelectedItems else { return true }
        return indexPaths.isEmpty
    }
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let previousIndexPath = context.previouslyFocusedIndexPath,
            let cell = collectionView.cellForItem(at: previousIndexPath) as? MotivationCollectionViewCell {
            cell.imageView.adjustsImageWhenAncestorFocused = false
            coordinator.addCoordinatedAnimations({() -> Void in
                context.previouslyFocusedView!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: { _ in })
        }
        
        if let indexPath = context.nextFocusedIndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? MotivationCollectionViewCell{
            cell.imageView.adjustsImageWhenAncestorFocused = true
            coordinator.addCoordinatedAnimations({() -> Void in
                context.nextFocusedView!.transform = CGAffineTransform(scaleX: self.focusValue, y: self.focusValue)
            }, completion: { _ in })
            collectionView.scrollToItem(at: indexPath, at: [.centeredHorizontally], animated: true)
        }
    }
}

extension FavouritesViewController: NSFetchedResultsControllerDelegate {
    // MARK: NSFetchedResultsController delegate
    // Used GIST: https://gist.github.com/AppsTitude/ce072627c61ea3999b8d#file-uicollection-and-nsfetchedresultscontrollerdelegate-integration-swift-L78
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == NSFetchedResultsChangeType.insert {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        } else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        } else if type == NSFetchedResultsChangeType.move {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        } else if type == NSFetchedResultsChangeType.delete {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        if type == NSFetchedResultsChangeType.insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        } else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        } else if type == NSFetchedResultsChangeType.delete {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}
