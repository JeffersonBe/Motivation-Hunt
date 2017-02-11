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
import Toucan
import SnapKit
import Alamofire
import GoogleAnalytics
import DZNEmptyDataSet
import Onboard
import SwiftyUserDefaults
import Segmentio
import IoniconsSwift
import DeviceKit

class MotivationFeedViewController: UIViewController {
    
    var collectionView: UICollectionView!
    var segmentioView: Segmentio!
    var segmentioContentDictionary: [SegmentioItem] = []
    var currentSegmentioItem: Theme? = nil
    var indicator = CustomUIActivityIndicatorView()
    let refreshCtrl = UIRefreshControl()
    let layer = CAGradientLayer()
    var sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Initialize delegate
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "addedDate", ascending: false)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
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

extension MotivationFeedViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "MotivationFeedViewController")
        
        let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
        tracker?.send(builder as! [AnyHashable: Any])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Defaults[.haveSeenOnBoarding] == nil || false {
            let onboard = Onboarding().presentOnboarding()
            onboard.modalPresentationStyle = .fullScreen
            onboard.modalTransitionStyle = .coverVertical
            present(onboard, animated: true, completion: nil)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        flowLayout.invalidateLayout()
    }
    
    override func viewDidLayoutSubviews() {
        if let rectNavigationBar = navigationController?.navigationBar.frame,
            let rectTabBar = tabBarController?.tabBar.frame {
            let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
            let navigationBarSpace = rectNavigationBar.size.height + rectNavigationBar.origin.y
            let rectNavigationBarHeight = rectNavigationBar.size.height
            let tabBarSpace = rectTabBar.size.height + rectTabBar.origin.x
            collectionView.contentInset = UIEdgeInsetsMake(navigationBarSpace + 100, 0, tabBarSpace, 0)
            segmentioView.snp.updateConstraints({ (make) in
                make.top.equalTo(rectNavigationBarHeight + statusBarHeight)
                make.width.equalTo(view)
            })
        }
    }
    
    func setupUI() {
        segmentioView = Segmentio()
        view.addSubview(segmentioView, options: .useAutoresize)
        segmentioView.snp.makeConstraints { (make) in
            make.top.equalTo(125)
            make.height.equalTo(100)
            make.width.equalTo(view)
            make.centerX.equalTo(view)
        }
        
        segmentioView.setup(content: segmentioContent(),
                            style: .imageOverLabel,
                            options: segmentOptions())
        
        segmentioView.selectedSegmentioIndex = 3
        
        segmentioView.valueDidChange = { segmentio, segmentIndex in
            switch segmentIndex {
            case 0:
                self.currentSegmentioItem = .Money
            case 1:
                self.currentSegmentioItem = .Success
            case 2:
                self.currentSegmentioItem = .Love
            default:
                self.currentSegmentioItem = .All
            }
            
            guard self.currentSegmentioItem != Theme.All else {
                self.navigationItem.rightBarButtonItem = nil
                self.updateFetch(theme: self.currentSegmentioItem!)
                self.refreshCtrl.removeFromSuperview()
                return
            }
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh, target: self, action: #selector(self.addNewMotivationItem))
            self.refreshCtrl.addTarget(self, action: #selector(MotivationFeedViewController.addNewMotivationItem), for: .valueChanged)
            self.collectionView?.addSubview(self.refreshCtrl)
            self.updateFetch(theme: self.currentSegmentioItem!)
        }
        
        // Blur View below Segmentio view
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        view.insertSubview(blurEffectView, belowSubview: segmentioView)
        blurEffectView.snp.makeConstraints { (make) in
            make.size.equalTo(segmentioView)
            make.center.equalTo(segmentioView)
        }
        
        // Configure CollectionView
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(motivationCollectionViewCell.self, forCellWithReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier)
        collectionView.backgroundColor = #colorLiteral(red: 0.1019897072, green: 0.1019897072, blue: 0.1019897072, alpha: 1)
        collectionView.allowsMultipleSelection = false
        view.insertSubview(collectionView, belowSubview: blurEffectView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }
}

extension MotivationFeedViewController {
    func segmentioContent() -> [SegmentioItem] {
        segmentioContentDictionary = [SegmentioItem]()
        let moneyItem = SegmentioItem(
            title: Theme.Money.rawValue,
            image: Ionicons.cash.image(40, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        )
        segmentioContentDictionary.append(moneyItem)
        let successItem = SegmentioItem(
            title: Theme.Success.rawValue,
            image: Ionicons.trophy.image(40, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        )
        segmentioContentDictionary.append(successItem)
        let loveItem = SegmentioItem(
            title: Theme.Love.rawValue,
            image: Ionicons.heart.image(40, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        )
        segmentioContentDictionary.append(loveItem)
        let allItem = SegmentioItem(
            title: Theme.All.rawValue,
            image: Ionicons.iosMore.image(40, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        )
        segmentioContentDictionary.append(allItem)
        return segmentioContentDictionary
    }
    
    func segmentioIndicatorOptions() -> SegmentioIndicatorOptions {
        return SegmentioIndicatorOptions(
            type: .bottom,
            ratio: 1,
            height: 5,
            color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        )
    }
    
    func segmentioHorizontalSeparatorOptions() -> SegmentioHorizontalSeparatorOptions {
        return SegmentioHorizontalSeparatorOptions(
            type: SegmentioHorizontalSeparatorType.bottom, // Top, Bottom, TopAndBottom
            height: 1,
            color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        )
    }
    
    func segmentioVerticalSeparatorOptions() -> SegmentioVerticalSeparatorOptions {
        return SegmentioVerticalSeparatorOptions(
            ratio: 0.2, // from 0.1 to 1
            color: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        )
    }
    
    func segmentioState(backgroundColor: UIColor, titleFont: UIFont, titleTextColor: UIColor) -> SegmentioState {
        return SegmentioState(backgroundColor: backgroundColor, titleFont: titleFont, titleTextColor: titleTextColor)
    }
    
    func segmentioStates() -> SegmentioStates {
        return SegmentioStates(
            defaultState: SegmentioState (
                backgroundColor: UIColor.clear,
                titleFont: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                titleTextColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ),
            selectedState: SegmentioState (
                backgroundColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1),
                titleFont: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                titleTextColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ),
            highlightedState: SegmentioState (
                backgroundColor: #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 0.5),
                titleFont: UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize),
                titleTextColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            )
        )
    }
    
    func segmentOptions() -> SegmentioOptions {
        return SegmentioOptions(
            backgroundColor: UIColor.clear,
            maxVisibleItems: 3,
            scrollEnabled: true,
            indicatorOptions: segmentioIndicatorOptions(),
            horizontalSeparatorOptions: segmentioHorizontalSeparatorOptions(),
            verticalSeparatorOptions: segmentioVerticalSeparatorOptions(),
            imageContentMode: UIViewContentMode.center,
            labelTextAlignment: NSTextAlignment.center,
            segmentStates: segmentioStates()
        )
    }
}

extension MotivationFeedViewController {

    func savedItem(sender: UIButton) {
        // Button is nested in barActionView > contentView > Cell
        guard let cell = sender.superview?.superview?.superview as? motivationCollectionViewCell,
            let indexPath = collectionView.indexPath(for: cell) else {
                return
        }
        
        let motivationItem = fetchedResultsController.object(at: indexPath)
        if motivationItem.saved {
            cell.favoriteBarButton.setImage(Ionicons.iosHeart.image(35, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), for: .normal)
        } else {
            cell.favoriteBarButton.setImage(Ionicons.iosHeartOutline.image(35, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), for: .normal)
        }
        CoreDataStack.shared.persistentContainer.performBackgroundTask { (NSManagedObjectContext) in
            motivationItem.saved = motivationItem.saved ? false : true
            CoreDataStack.shared.saveContext()
        }
    }
    
    func shareMotivationItem(sender: UIButton) {
        // Button is nested in barActionView > contentView > Cell
        guard let cell = sender.superview?.superview?.superview as? motivationCollectionViewCell,
            let indexPath = collectionView.indexPath(for: cell) else {
                return
        }
        let motivation = fetchedResultsController.object(at: indexPath)
        let motivationToShare = [motivation.itemTitle, motivation.itemDescription, "\(MHClient.Resources.youtubeBaseUrl)\(motivation.itemVideoID)"]
        let activityViewController = UIActivityViewController(activityItems: motivationToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
        
        activityViewController.popoverPresentationController?.sourceView = cell.imageView
        activityViewController.popoverPresentationController?.sourceRect = cell.imageView.bounds
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    func playVideo(sender: UIButton) {
        // Button is nested in contentView > Cell
        guard let cell = sender.superview?.superview as? motivationCollectionViewCell else { return }
        let tracker = GAI.sharedInstance().defaultTracker
        let builder: NSObject = GAIDictionaryBuilder.createEvent(
            withCategory: "MotivationFeedViewController",
            action: "playVideo",
            label: "User play video",
            value: nil).build()
        tracker?.send(builder as! [AnyHashable: Any])
        
        cell.videoPlayer.play()
        
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       options: UIViewAnimationOptions.curveEaseOut,
                       animations: {
            cell.videoPlayer.alpha = 1
            cell.playButton.alpha = 0
            cell.imageView.alpha = 0
        }, completion: nil)
    }
    
    func deleteVideo(sender: UIButton) {
        guard let cell = sender.superview?.superview?.superview as? motivationCollectionViewCell,
            let indexPath = collectionView.indexPath(for: cell) else {
                return
        }
        showDeleteActionSheet(for: indexPath)
    }
    
    func showDeleteActionSheet(for indexPath: IndexPath) {
        let optionMenu = UIAlertController(title: "Are you sure to delete this video?",
                                           message: "This cannot be undone!",
                                           preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let motivation = self.fetchedResultsController.object(at: indexPath)
            
            motivation.prepareForDeletion()
            self.fetchedResultsController.managedObjectContext.delete(motivation)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            optionMenu.dismiss(animated: true, completion: nil)
        })
        
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func addNewMotivationItem() {
        indicator.startActivity()
        view.addSubview(indicator)

        let downloader = MotivationVideoDownloader()

        if let currentTheme = currentSegmentioItem {
            downloader.downloadNewItemVideo(theme: currentTheme, completionHandler: { (success, videoItems) in
                guard success, videoItems != nil else {
                    DispatchQueue.main.async {
                        self.indicator.stopActivity()
                        self.indicator.removeFromSuperview()
                        let errorAlert = UIAlertController(title: "Oops… Unable to load feed", message: "We haven't been able to retrieves your content", preferredStyle: UIAlertControllerStyle.alert)
                        errorAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                        self.present(errorAlert, animated: true, completion: nil)
                    }
                    return
                }
            
                for item in videoItems! {
                    CoreDataStack.shared.persistentContainer.performBackgroundTask { (NSManagedObjectContext) in
                        let _ = VideoItem(
                            itemVideoID: item["itemVideoID"] as! String,
                            itemTitle: item["itemTitle"] as! String,
                            itemDescription: item["itemDescription"] as! String,
                            itemThumbnailsUrl: item["itemThumbnailsUrl"] as! String,
                            saved: false,
                            theme: item["theme"] as! String,
                            context: self.sharedContext)
                    }
                    CoreDataStack.shared.saveContext()
                }
            })
        }
        
        DispatchQueue.main.async {
            self.indicator.stopActivity()
            self.indicator.removeFromSuperview()
        }
        
        if refreshCtrl.isRefreshing {
            refreshCtrl.endRefreshing()
        }
    }
}

extension MotivationFeedViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let title = "You don't have any videos yet"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: title, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let description = "Choose one of the themes to see motivational videos!"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: description, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return #imageLiteral(resourceName: "iconFeed")
    }
}

extension MotivationFeedViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        
        if sectionInfo.numberOfObjects != 0 {
            DispatchQueue.main.async{
                collectionView.reloadEmptyDataSet()
            }
        }
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let motivationItem = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier, for: indexPath) as! motivationCollectionViewCell
        cell.videoPlayer.delegate = self
        cell.textLabel.text = motivationItem.itemTitle
        if motivationItem.image == nil {
            _ = MHClient.sharedInstance.taskForImage(motivationItem.itemThumbnailsUrl) { imageData, error in
                guard error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    motivationItem.image = UIImage(data: imageData!)
                    cell.imageView.image = Toucan(image: motivationItem.image!).resize(CGSize(width: cell.frame.width - 10, height: cell.frame.width / 1.8), fitMode: Toucan.Resize.FitMode.crop).maskWithRoundedRect(cornerRadius: 10).image
                }
            }
        }
        
        if motivationItem.saved {
            cell.favoriteBarButton.setImage(Ionicons.iosHeart.image(35, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), for: .normal)
        } else {
            cell.favoriteBarButton.setImage(Ionicons.iosHeartOutline.image(35, color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), for: .normal)
        }
    
        cell.playButton.addTarget(self,
                                  action: #selector(MotivationFeedViewController.playVideo),
                                  for: .touchUpInside)
        cell.imageViewButton.addTarget(self,
                                       action: #selector(MotivationFeedViewController.playVideo),
                                       for: .touchUpInside)
        cell.favoriteBarButton.addTarget(self,
                                         action: #selector(MotivationFeedViewController.savedItem),
                                         for: .touchUpInside)
        cell.shareBarButton.addTarget(self,
                                      action: #selector(MotivationFeedViewController.shareMotivationItem),
                                      for: .touchUpInside)
        cell.deleteBarButton.addTarget(self,
                                       action: #selector(MotivationFeedViewController.deleteVideo),
                                       for: .touchUpInside)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? motivationCollectionViewCell {
            let motivationItem = fetchedResultsController.object(at: indexPath)
            cell.videoPlayer.loadVideoID(motivationItem.itemVideoID)
            cell.imageView.alpha = 0
            cell.playButton.alpha = 0
            cell.videoPlayer.alpha = 0
            
            if motivationItem.image != nil {
                DispatchQueue.main.async {
                    cell.imageView.image = Toucan(image: motivationItem.image!).resize(CGSize(width: cell.frame.width - 10, height: cell.frame.width / 1.8), fitMode: Toucan.Resize.FitMode.crop).maskWithRoundedRect(cornerRadius: 10).image
                }
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                cell.imageView.alpha = 1
                cell.playButton.alpha = 0.7
            }, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? motivationCollectionViewCell {
            cell.videoPlayer.stop()
        }
    }
}

extension MotivationFeedViewController : UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let motivationItem = fetchedResultsController.object(at: indexPath)
            guard motivationItem.image != nil else {
                _ = MHClient.sharedInstance.taskForImage(motivationItem.itemThumbnailsUrl) { imageData, error in
                    guard error == nil else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        motivationItem.image = UIImage(data: imageData!)
                    }
                }
                return
            }
        }
    }
}

extension MotivationFeedViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemsPerRow: CGFloat = 1
        var paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        var availableWidth = view.frame.width - paddingSpace
        var widthPerItem = availableWidth / itemsPerRow
        var heightPerItem: CGFloat
        
        guard Device().isPhone else {
            sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
            itemsPerRow = 2
            paddingSpace = sectionInsets.left * (itemsPerRow + 1)
            availableWidth = view.frame.width - paddingSpace
            widthPerItem = availableWidth / itemsPerRow
            
            // Defining item heigh for iPad on default portrait mode
            switch Device() {
            case .iPadPro9Inch, .simulator(.iPadPro9Inch):
                heightPerItem = widthPerItem * 0.8
            case .iPadPro12Inch, .simulator(.iPadPro12Inch):
                heightPerItem = widthPerItem * 0.75
            default:
                heightPerItem = widthPerItem * 0.8
            }
            
            // Defining item heigh for iPad on landscape mode
            if (UIApplication.shared.statusBarOrientation.isLandscape) {
                switch Device() {
                case .iPadPro12Inch, .iPadPro9Inch, .simulator(.iPadPro12Inch), .simulator(.iPadPro9Inch):
                    heightPerItem = widthPerItem * 0.7
                default:
                    heightPerItem = widthPerItem * 0.8
                }
            }
            
            return CGSize(width: widthPerItem, height: heightPerItem)
        }
        
        // Defining item heigh for iPhone on default portrait mode
        switch Device() {
        case .iPhone5, .iPhone5c, .iPhone5s, .iPhoneSE, .simulator(.iPhone5), .simulator(.iPhone5c), .simulator(.iPhone5s), .simulator(.iPhoneSE):
            heightPerItem = widthPerItem * 0.85
        case .iPhone6, .iPhone6s, .iPhone6Plus, .simulator(.iPhone6), .simulator(.iPhone6s), .simulator(.iPhone6Plus):
            heightPerItem = widthPerItem * 0.8
        default:
            heightPerItem = widthPerItem * 0.8
        }
        
        // Defining item heigh for iPhone on landscape mode
        if (UIApplication.shared.statusBarOrientation.isLandscape) {
            switch Device() {
            case .iPhone5, .iPhone5c, .iPhone5s, .iPhoneSE, .simulator(.iPhone5), .simulator(.iPhone5c), .simulator(.iPhone5s), .simulator(.iPhoneSE):
                heightPerItem = widthPerItem * 0.475
            case .iPhone6, .iPhone6s, .iPhone6Plus, .simulator(.iPhone6), .simulator(.iPhone6s), .simulator(.iPhone6Plus):
                heightPerItem = widthPerItem * 0.6
            default:
                heightPerItem = widthPerItem * 0.5
            }
        }
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        collectionView!.collectionViewLayout.invalidateLayout()
    }
}

extension MotivationFeedViewController: YouTubePlayerDelegate {
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        switch (playerState) {
        case .Queued: break
        case .Ended: break
        case .Buffering:
            DispatchQueue.main.async {
                self.indicator.startActivity()
                self.view.addSubview(self.indicator)
            }
        case .Playing:
            DispatchQueue.main.async {
                self.indicator.stopActivity()
                self.indicator.removeFromSuperview()
            }
        case .Paused:
            DispatchQueue.main.async {
                self.indicator.stopActivity()
                self.indicator.removeFromSuperview()
            }
        case .Unstarted:
            DispatchQueue.main.async {
                self.indicator.stopActivity()
                self.indicator.removeFromSuperview()
            }
        }
    }
}

extension MotivationFeedViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        case .update:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        case .move:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        case .delete:
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
        switch (type) {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        case .update:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        case .delete:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        case .move:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveSection(sectionIndex, toSection: sectionIndex)
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
    
    func updateFetch(theme: Theme) {
        if currentSegmentioItem == nil || currentSegmentioItem == .All {
            fetchedResultsController.fetchRequest.predicate = nil
        } else {
            let predicate = NSPredicate(format: "theme = '\(currentSegmentioItem!)'")
            fetchedResultsController.fetchRequest.predicate = predicate
        }
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            Log.info("Error: \(error.localizedDescription)")
        }
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
            addNewMotivationItem()
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}
