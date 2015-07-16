//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRBrowserBaseViewController.h
//  Secure Browser
//
//  Created by Kenny Roethel on 2/13/13.
//

#import "AIRTTSEngine.h"
#import "UIWebView+AIR.h"
#import "WKWebView+AIR.h"

/**   Base Class for AIR Browser View Controller(s).
 
 Provides some basic functionality for the browser. eg. WebView outlet, Javascript execution utility
 methods.
 
 */
@interface AIRBrowserBaseViewController : UIViewController

- (NSString*)orientationMaskString;

/**
 *  Execute javascript in the webview
 *  @param javascript the javascript to execute
 *  @param message the message to log
 */
- (NSString*)sendJavascript:(NSString*)javascript logMessage:(NSString*)message;

/* Log a value/message pair. The base implementation does nothing, it is up
 to subclassesses to implement this how they would like. */
- (void)logValue:(NSString*)value withMessage:(NSString*)message;

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet WKWebView *wkWebView;
@property (nonatomic, retain) AIRTTSEngine *ttsEngine;
@property (nonatomic, assign) UIInterfaceOrientationMask orientationMask;
@property (nonatomic, retain) NSString *jsResult;

@end
