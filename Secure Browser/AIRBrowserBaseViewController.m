//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRBrowserBaseViewController.m
//  Secure Browser
//
//  Created by Kenny Roethel on 2/13/13.
//

#import "AIRBrowserBaseViewController.h"
#import "Reachability.h"

static NSString *const kAudioCommandPrefix = @"AIRMobile.setAudio";

@interface AIRBrowserBaseViewController ()

@end

@implementation AIRBrowserBaseViewController

#pragma mark - NSObject

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self)
    {
        self.orientationMask = UIInterfaceOrientationMaskLandscape;
        
        [self addNotificationObservers];
    }

    return self;
}

- (void)dealloc
{
    self.ttsEngine = nil;
    self.webView = nil;
    self.wkWebView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#pragma mark Utility

- (void)addNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged:)
                                                 name:UIAccessibilityVoiceOverStatusChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(guidedAccessStatusChanged:)
                                                 name:UIAccessibilityGuidedAccessStatusDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:)
                                                 name: kReachabilityChangedNotification object: nil];
}

- (void)setOrientationMask:(UIInterfaceOrientationMask)orientationMask
{
    _orientationMask = orientationMask;
    
    if(_orientationMask == UIInterfaceOrientationMaskPortrait)
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    if(_orientationMask == UIInterfaceOrientationMaskPortraitUpsideDown)
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortraitUpsideDown];
    if(_orientationMask == UIInterfaceOrientationMaskLandscapeLeft)
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
    if(_orientationMask == UIInterfaceOrientationMaskLandscapeRight)
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
}

- (NSString*)orientationMaskString
{
    NSString *orientationLock = @"none";
    if(_orientationMask == UIInterfaceOrientationMaskPortrait)
        orientationLock = @"portait";
    if(_orientationMask == UIInterfaceOrientationMaskPortraitUpsideDown)
        orientationLock = @"portrait";
    if(_orientationMask == UIInterfaceOrientationMaskLandscapeLeft)
        orientationLock = @"landscape";
    if(_orientationMask == UIInterfaceOrientationMaskLandscapeRight)
        orientationLock = @"landscape";
    
    return orientationLock;
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return self.orientationMask;
}

#pragma mark - Utility

- (NSString*)jsHandler:(NSString*)res {
    return res;
}

- (NSString*)sendJavascript:(NSString*)javascript logMessage:(NSString*)message
{
    if(![javascript hasPrefix:kAudioCommandPrefix])
    {
        [self logValue:javascript withMessage:message ? message : @"Calling Javascript"];
    }
    else
    {
        [self logValue:@"Sending Audio" withMessage:@"..."];
    }
    
    NSString *result = @"";
    
    if ([WKWebView class]) {
        [self.wkWebView evaluateJavaScript:javascript completionHandler:^(NSString* jsId, NSError *err){
            self.jsResult = jsId;
        }];
    } else {
        result = [self.webView stringByEvaluatingJavaScriptFromString:javascript];
    }
    
    [self logValue:result withMessage:@"Result"];
    
    return result;
}

- (void)logValue:(NSString*)value withMessage:(NSString*)message
{
    //Do nothing - subclasses may handle if they choose to log
}

- (void)voiceOverStatusChanged:(NSNotification*)note
{
    
}

- (void)guidedAccessStatusChanged:(NSNotification*)note
{
    
}

- (void)willEnterBackground:(NSNotification*)note
{
    
}

- (void)willEnterForeground:(NSNotification*)note
{
    
}

- (void)reachabilityChanged:(NSNotification*)note
{
    
}

@end
