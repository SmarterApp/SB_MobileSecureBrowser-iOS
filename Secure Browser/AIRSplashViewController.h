//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRSplashViewController.h
//  Secure Browser
//
//  Created by Kenny Roethel on 11/15/12.
//
//  Splash View Controller - Provides initial status check before displaying the
//  web controller.

#import <UIKit/UIKit.h>
#import "Reachability.h"

@protocol AIRSpashViewControllerDelegate <NSObject>

/** Called when the check is complete and the controller should be dismised. */
- (void)splashViewControllerDidComplete;

@end

/**
 *  Provides a splash screen while the application initially loads. Once the controller
 *  has started and has determined it is okay to continue, the controllers delegate method is called indicating
 *  completion. Currently the only check performed during the load is for network connectivity.
 */
@interface AIRSplashViewController : UIViewController

/** Initialize the controller with a reachability instance, and a delegate. If reachability instance is
 *  provided, one is automatically created. 
 *  @param reachability the reachability obect to use when checking connection status.
 *  @param delegate the delagate to call when complete.
 */
- (id)initWithReachability:(Reachability*)reachability delegate:(id<AIRSpashViewControllerDelegate>)delegate;

@property (nonatomic, assign) id<AIRSpashViewControllerDelegate> delegate;
@property (nonatomic, retain) Reachability *reachability;

@end
