//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRAppDelegate.h
//  Secure Browser
//
//  Created by Kenny Roethel on 11/15/12.
//

#import <UIKit/UIKit.h>
#import "UIWebView+AIR.h"
#import "Reachability.h"
#import "AIRWebViewController.h"

/** UIApplicationDelegate implementation used as the
 *  Application Delegate for the Mobile Secure Browswer.
 *  The primary role of this class is to handle the application lifecyle
 *  events, and constructing and presenting the user interface at startup.
 */
@interface AIRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) AIRWebViewController *webController;
@property (strong, nonatomic) NSTimer *clipboardTimer;
@property (strong, nonatomic) NSDate *startTime;

@end
