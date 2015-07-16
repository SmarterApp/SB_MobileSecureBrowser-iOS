//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRWebViewController.h
//  Secure Browser
//
//  Created by Kenny Roethel on 11/15/12.
//

#import "UIWebView+AIR.h"
#import "WKWebView+AIR.h"
#import "AIRBrowserBaseViewController.h"
#import "Reachability.h"

/** Main Application View Controller. Displays the web content and manages
 *  its interactions via javascript.
 */
@interface AIRWebViewController : AIRBrowserBaseViewController <UIWebViewDelegate, WKNavigationDelegate>

- (id)initWithReachability:(Reachability*)reachability;

@property (nonatomic, strong) Reachability *reachability;

@end
