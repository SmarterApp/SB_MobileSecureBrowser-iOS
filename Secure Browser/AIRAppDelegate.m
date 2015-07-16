//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRAppDelegate.m
//  Secure Browser
//
//  Created by Kenny Roethel on 11/15/12.
//
#undef DEBUG
#import "AIRAppDelegate.h"
#import "AIRDebugWebViewController.h"
#import "AIRSplashViewController.h"
#import "Reachability.h"
#import "UIWebView+AIR.h"

static NSString *const kUserAgentString = @"SmarterMobileSecureBrowser/1.0";

@interface AIRAppDelegate () <AIRSpashViewControllerDelegate>
@end

@implementation AIRAppDelegate

#pragma mark - NSObject

- (void)dealloc
{
    [_reachability release];
    [_window release];
    [_clipboardTimer invalidate];
    [_clipboardTimer release];
    
    [super dealloc];
}

#pragma mark - UIApplication Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *model = [[UIDevice currentDevice] model];
    NSString *os = [[UIDevice currentDevice] systemName];
    NSString *osVer = [[UIDevice currentDevice] systemVersion];
    
    NSString *agentSuffix = [NSString stringWithFormat:@"OS/%@ Version/%@ Model/%@", os, osVer, model];
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString* secretAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    [webView release];
    
    NSString *userAgent = [NSString stringWithFormat:@"%@ %@ %@", secretAgent, kUserAgentString, agentSuffix];
    NSLog(@"%@", userAgent);
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent" : userAgent}];
   
    self.clipboardTimer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(clearClipboard:) userInfo:nil repeats:YES];
    self.reachability = [Reachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor lightGrayColor];
    
    BOOL devMode = [[UIApplication sharedApplication] isDevelopementBuild];
    
    AIRSplashViewController *splash = [[[AIRSplashViewController alloc] initWithReachability:self.reachability delegate:self] autorelease];
    
    if(devMode)
    {
        _webController = [[[AIRDebugWebViewController alloc] initWithReachability:_reachability] autorelease];
    
        UINavigationController *navCtl = [[[UINavigationController alloc] initWithRootViewController:_webController] autorelease];
       
        self.window.rootViewController = navCtl;
    }
    else
    {
        _webController = [[[AIRWebViewController alloc] initWithReachability:_reachability] autorelease];
        _webController.reachability = self.reachability;
        
        self.window.rootViewController = _webController;
    }

    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:splash animated:NO completion:NULL];
    
    self.startTime = [NSDate date];
    
    return YES;
}

- (void)clearClipboard:(NSTimer*)timer
{
    [[UIPasteboard generalPasteboard] setString:@""];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.reachability stopNotifier];
    
    [self.clipboardTimer invalidate];
    self.clipboardTimer = nil;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.reachability startNotifier];
    
    self.clipboardTimer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(clearClipboard:) userInfo:nil repeats:YES];
    self.startTime = [NSDate date];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return self.webController.orientationMask;
}

#pragma mark - AIRSplashViewController Delegate

- (void)splashViewControllerDidComplete
{
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
