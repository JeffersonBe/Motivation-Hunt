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
import TBEmptyDataSet
import Onboard
import SwiftyUserDefaults

let nextPageTokenConstant = "nextPageToken"

class MotivationFeedViewController: UIViewController {

    var collectionView: UICollectionView!
    var progressView: UIProgressView!
    var indicator = CustomUIActivityIndicatorView()
    let refreshCtrl = UIRefreshControl()
    let layer = CAGradientLayer()
    var blockOperations: [BlockOperation] = []

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
    }

    override func viewDidAppear(_ animated: Bool) {
//        if Defaults[.haveSeenOnBoarding] == nil || false {
//            onboarding()
//        }
    }

    func onboarding() {
        // Initialize onboarding view controller
        var onboardingVC = OnboardingViewController()

        // Create slides
        let firstPage = OnboardingContentViewController
            .content(withTitle: "Welcome to Motivation Hunt!",
                              body: "Swipe to begin",
                              image: nil,
                              buttonText: nil,
                              action: nil)

        let secondPage = OnboardingContentViewController
            .content(withTitle: "Watch and be inspire",
                              body: "Watch and be inspire by new daily motivational videos.",
                              image: UIImage(named: "onboardingFeedIcon"),
                              buttonText: nil,
                              action: nil)

        let thirdPage = OnboardingContentViewController
            .content(withTitle: "Save your favorite",
                              body: "Need a boost? Your favorites videos are easily accessible to you.",
                              image: UIImage(named: "onboardingFeaturedIcon"),
                              buttonText: nil,
                              action: nil)

        let fourthPage = OnboardingContentViewController
            .content(withTitle: "Challenge yourself",
                              body: "Define your challenge and then complete it!",
                              image: UIImage(named: "onboardingChallengeIcon"),
                              buttonText: nil,
                              action: nil)

        // Define onboarding view controller properties
        onboardingVC = OnboardingViewController.onboard(withBackgroundImage: UIImage.fromColor(UIColor.black), contents: [firstPage, secondPage, thirdPage, fourthPage])
        onboardingVC.pageControl.pageIndicatorTintColor = UIColor.darkGray
        onboardingVC.pageControl.currentPageIndicatorTintColor = UIColor.white
        onboardingVC.allowSkipping = true
        onboardingVC.skipButton.setTitleColor(UIColor.white, for: UIControlState())
        onboardingVC.skipButton.setTitle("Skip", for: UIControlState())
        onboardingVC.skipHandler = {
            self.dismiss(animated: true, completion: nil)
            Defaults[.haveSeenOnBoarding] = true
        }
        onboardingVC.fadePageControlOnLastPage = true
        onboardingVC.fadeSkipButtonOnLastPage = true
        
        // Present presentation
        parent!.present(onboardingVC, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "MotivationFeedViewController")

        let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
        tracker?.send(builder as! [AnyHashable: Any])
    }

    // Initialize CoreData and NSFetchedResultsController

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController<VideoItem> = {
        let fetchRequest: NSFetchRequest<VideoItem> = VideoItem.fetchRequest() as! NSFetchRequest<VideoItem>
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
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }

        blockOperations.removeAll(keepingCapacity: false)
    }
}

extension MotivationFeedViewController {

    override func viewDidLayoutSubviews() {
        layer.frame = view.frame
        if let rectNavigationBar = navigationController?.navigationBar.frame, let rectTabBar = tabBarController?.tabBar.frame  {
            let navigationBarSpace = rectNavigationBar.size.height + rectNavigationBar.origin.y
            let tabBarSpace = rectTabBar.size.height + rectTabBar.origin.x
            collectionView.contentInset = UIEdgeInsetsMake(navigationBarSpace, 0, tabBarSpace, 0)
        }
    }

    func setupUI() {

        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) /* #000000 */
        // Configure CollectionView
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(motivationCollectionViewCell.self, forCellWithReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier)
        collectionView.backgroundColor = UIColor.clear /* #000000 */
        collectionView.allowsMultipleSelection = false
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(view)
            make.width.equalTo(view)
            make.bottom.equalTo(view.snp.bottom)
            make.center.equalTo(view)
        }

        refreshCtrl.addTarget(self, action: #selector(MotivationFeedViewController.addNewMotivationItem), for: .valueChanged)
        collectionView?.addSubview(refreshCtrl)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh, target: self, action: #selector(addNewMotivationItem))

        // Set background View
        layer.frame = view.frame
        let color1 = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor /* #000000 */
        let color2 = UIColor(red: 0.1294, green: 0.1294, blue: 0.1294, alpha: 1.0).cgColor /* #212121 */
        layer.colors = [color1, color2]
        layer.masksToBounds = true
        layer.contentsGravity = kCAGravityResize
        view.layer.insertSublayer(layer, below: collectionView.layer)

        navigationController?.hidesBarsOnSwipe = true
        setNeedsStatusBarAppearanceUpdate()
    }

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {}

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

extension MotivationFeedViewController {

    func savedItem(_ gestureRecognizer: UIGestureRecognizer) {
        let tapPoint: CGPoint = gestureRecognizer.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: tapPoint)
        let objet = fetchedResultsController.object(at: indexPath!)

        DispatchQueue.main.async {
            objet.saved = objet.saved ? false : true
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }

    func playVideo(_ gestureRecognizer: UIGestureRecognizer) {
        let tracker = GAI.sharedInstance().defaultTracker
        let builder: NSObject = GAIDictionaryBuilder.createEvent(
            withCategory: "MotivationFeedViewController",
            action: "playVideo",
            label: "User play video",
            value: nil).build()
        tracker?.send(builder as! [AnyHashable: Any])

        let tapPoint: CGPoint = gestureRecognizer.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: tapPoint)
        let cell = collectionView.cellForItem(at: indexPath!) as! motivationCollectionViewCell

        cell.videoPlayer.play()

        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            cell.videoPlayer.alpha = 1
            cell.playButton.alpha = 0
            cell.imageView.alpha = 0
            }, completion: nil)
    }

    func shareMotivation(_ gestureRecognizer: UIGestureRecognizer) {
        let tapPoint: CGPoint = gestureRecognizer.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: tapPoint)
        let cell = collectionView.cellForItem(at: indexPath!) as! motivationCollectionViewCell
        let motivation = fetchedResultsController.object(at: indexPath!)
        let motivationToShare = [motivation.itemTitle, motivation.itemDescription, "\(MHClient.Resources.youtubeBaseUrl)\(motivation.itemVideoID)"]
        let activityViewController = UIActivityViewController(activityItems: motivationToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]

        activityViewController.popoverPresentationController?.sourceView = cell.imageView
        activityViewController.popoverPresentationController?.sourceRect = cell.imageView.bounds

        self.present(activityViewController, animated: true, completion: nil)
    }

    func addNewMotivationItem() {
        indicator.startActivity()
        view.addSubview(indicator)
        var mutableParameters: [String : AnyObject]
        let theme = "motivation+success"

        let parameters: [String : AnyObject] = [
            MHClient.JSONKeys.part: MHClient.JSONKeys.snippet as AnyObject,
            MHClient.JSONKeys.order: MHClient.JSONKeys.viewCount as AnyObject,
            MHClient.JSONKeys.query: theme as AnyObject,
            MHClient.JSONKeys.type: MHClient.JSONKeys.videoType as AnyObject,
            MHClient.JSONKeys.videoDefinition: MHClient.JSONKeys.qualityHigh as AnyObject,
            MHClient.JSONKeys.maxResults: 10 as AnyObject,
            MHClient.JSONKeys.key: MHClient.Constants.ApiKey as AnyObject
        ]

        mutableParameters = parameters

        let defaults = UserDefaults.standard
        if let nextPageToken = defaults.string(forKey: nextPageTokenConstant) {
            mutableParameters["pageToken"] = "\(nextPageToken)" as AnyObject?
        }

        let request = Alamofire.request(MHClient.Resources.searchVideos, method: .get, parameters: mutableParameters)
        
        request.responseJSON { response in
            guard response.result.isSuccess else {
                DispatchQueue.main.async {
                    self.indicator.stopActivity()
                    self.indicator.removeFromSuperview()
                    let errorAlert = UIAlertController(title: "Oops… Unable to load feed", message: response.description, preferredStyle: UIAlertControllerStyle.alert)
                            errorAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                    }
                Log.warning("There was an error with your request: \(response.description)")
                return
            }
            
            let results = response.result.value as! [String:AnyObject]
            let items = results[MHClient.JSONResponseKeys.items] as! [[String:AnyObject]]
            let nextPageTokenKey = results["nextPageToken"] as! String
            let defaults = UserDefaults.standard
            defaults.set(nextPageTokenKey, forKey:nextPageTokenConstant)

            for item in items {
                guard let ID = item[MHClient.JSONResponseKeys.ID] as? [String:AnyObject],
                    let videoID = ID[MHClient.JSONResponseKeys.videoId] as? String,
                    let snippet = item[MHClient.JSONResponseKeys.snippet] as? [String:AnyObject],
                    let title = snippet[MHClient.JSONResponseKeys.title] as? String,
                    let description = snippet[MHClient.JSONResponseKeys.description] as? String
                    else {
                        Log.warning("Didn't successfully unwrap Youtube JSON")
                        return
                }
                
                DispatchQueue.main.async {
                    let _ = VideoItem(itemVideoID: videoID,
                                      itemTitle: title,
                                      itemDescription: description,
                                      itemThumbnailsUrl: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg",
                        saved: false,
                        theme: Theme.themeName.Motivation,
                        context: self.sharedContext)
                        // let _ = Item(item: videoItem as AnyObject, theme: Theme.themeName.Motivation, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance.saveContext()
                    self.indicator.stopActivity()
                    self.indicator.removeFromSuperview()
                }
            }
        }

        if refreshCtrl.isRefreshing {
            refreshCtrl.endRefreshing()
        }
    }
}

extension MotivationFeedViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let motivationItem = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier, for: indexPath) as! motivationCollectionViewCell
        configureCell(cell, withItem: motivationItem)
        return cell
    }

    func configureCell(_ cell: motivationCollectionViewCell, withItem motivationItem: VideoItem) {
        cell.videoPlayer.delegate = self
        cell.textLabel.text = motivationItem.itemTitle

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

        if motivationItem.saved {
            cell.favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.Heart), for: .normal)
        } else {
            cell.favoriteBarButton.setTitle(String.fontAwesomeIconWithName(.HeartO), for: .normal)
        }

        guard motivationItem.image != nil else {
            _ = MHClient.sharedInstance.taskForImage(motivationItem.itemThumbnailsUrl) { imageData, error in
                guard error == nil else {
                    return
                }
                
                DispatchQueue.main.async {
                    motivationItem.image = UIImage(data: imageData!)
                    cell.imageView.image = Toucan(image: motivationItem.image!).resize(CGSize(width: cell.frame.width - 10, height: cell.frame.width / 1.8), fitMode: Toucan.Resize.FitMode.crop).maskWithRoundedRect(cornerRadius: 10).image
                }
            }
            return
        }
        cell.imageView.image = Toucan(image: motivationItem.image!).resize(CGSize(width: cell.frame.width - 10, height: cell.frame.width / 1.8), fitMode: Toucan.Resize.FitMode.crop).maskWithRoundedRect(cornerRadius: 10).image
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

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let device = UIDevice.current.model
        let dimensioniPhone = view.frame.width
        var cellSize: CGSize = CGSize(width: dimensioniPhone, height: dimensioniPhone * 0.8)
        let dimensioniPad = (view.frame.width / 2) - 15

        if (device == "iPad" || device == "iPad Simulator") {
            cellSize = CGSize(width: dimensioniPad, height: dimensioniPad * 0.8)
        }
        return cellSize
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let device = UIDevice.current.model
        var edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        if (device == "iPad" || device == "iPad Simulator") {
            edgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }

        return edgeInsets
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
}
