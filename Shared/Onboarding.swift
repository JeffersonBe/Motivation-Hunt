//
//  Onboarding.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 05/02/2017.
//  Copyright © 2017 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import Onboard
import SwiftyUserDefaults

class Onboarding {

    func presentOnboarding() -> UIViewController {
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
            .content(withTitle: "Watch and be inspired",
                     body: "Watch and be inspired by new daily motivational videos.",
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
                     buttonText: "Add a challenge",
                     action: {
                        Defaults[.haveSeenOnBoarding] = true
                        
                        onboardingVC.dismiss(animated: true, completion: {
                            let window :UIWindow = UIApplication.shared.keyWindow!
                            
                            guard let tabBarController = window.rootViewController as? UITabBarController else {
                                return
                            }
                            
                            tabBarController.selectedIndex = 2
                            
                            if let topController = window.visibleViewController() {
                                Log.info(topController.isKind(of: ChallengeViewController.self))
                                if topController.isKind(of: ChallengeViewController.self) {
                                    let challengeViewController = topController as! ChallengeViewController
                                    challengeViewController.viewDidLoad()
                                    challengeViewController.editMode = false
                                    challengeViewController.showOrHideChallengeView()
                                }
                            }
                        })
            })
        
        // Define onboarding view controller properties
        onboardingVC = OnboardingViewController.onboard(withBackgroundImage: UIImage.fromColor(color: #colorLiteral(red: 0.1019897072, green: 0.1019897072, blue: 0.1019897072, alpha: 1)), contents: [firstPage, secondPage, thirdPage, fourthPage])
        onboardingVC.pageControl.pageIndicatorTintColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        onboardingVC.pageControl.currentPageIndicatorTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        onboardingVC.allowSkipping = true
        onboardingVC.skipButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: UIControlState())
        onboardingVC.skipButton.setTitle("Skip", for: UIControlState())
        onboardingVC.skipButton.accessibilityIdentifier = "skipButton"
        onboardingVC.skipHandler = {
            onboardingVC.dismiss(animated: true, completion: nil)
            Defaults[.haveSeenOnBoarding] = true
        }
        onboardingVC.fadePageControlOnLastPage = true
        onboardingVC.fadeSkipButtonOnLastPage = true
        
        return onboardingVC
    }
}
