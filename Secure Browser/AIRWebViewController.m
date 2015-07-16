//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRWebViewController.m
//  Secure Browser
//
//  Created by Kenny Roethel on 11/15/12.
//

#import <objc/runtime.h>
#import "AIRWebViewController.h"
#import "UIWebView+AIR.h"
#import "WKWebView+AIR.h"
#import "UIDevice+ProcessesAdditions.h"
#import <AVFoundation/AVFoundation.h>
#import "NSData+Base64MG.h"
#import "NSJSONSerialization+AIR.h"
#import "Reachability.h"
#import "AIRTTSEngine.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AIROpusAudioRecorder.h>
#import <AIROpusAudioPlayer.h>
#import "AIRProcesses.h"
#import "NSString+UUID.h"
#import "AIRJSCommand.h"
#import "UIScreen+AIR.h"
#import "AIRAppDelegate.h"
#import "UIDevice+OSBuildVersion.h"

static const float kKilobyteConversionFactor = 0.000976562;
static const float kAIRMobileAPIVersion = 3.0f;
static NSString *const kCustomURLIdentifier = @":##airMobile_msgsnd##";

static NSString *const kIdentifier = @"identifier";
static NSString *const kDefaultRegionKey = @"default_region_selection";

static NSString *const kDefaultUrl = @"http://browser.smarterbalanced.org/landing";
static NSString *const kIdentifierKey = @"identifier";

@interface AIRWebViewController () <AVAudioRecorderDelegate, AIRTTSDelegate, UIAlertViewDelegate>

@property (nonatomic, copy) NSString *defaultURL;
@property (nonatomic, copy) NSError *lastError;

@property (nonatomic, strong) AIROpusAudioRecorder *opusAudioRecorder;
@property (nonatomic, strong) AIROpusAudioPlayer *opusAudioPlayer;

@property (nonatomic, strong) AIRProcesses *processes;

@property (nonatomic) BOOL useWkWebView;

@end

@implementation AIRWebViewController

#pragma mark - NSObject

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        self.processes = [[AIRProcesses alloc] init];
        [self.processes beginMonitoringProcesses];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processesDidChange:) name:AIRProcessListDidChangeNotification object:nil];
        
        self.ttsEngine = [[AIRTTSEngine alloc] init];
        self.ttsEngine.delegate = self;
        
        [self configureDefaultUrl];
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        if ([WKWebView class]) {
            self.useWkWebView = YES;
        } else {
            self.useWkWebView = NO;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.processes endMonitoringProcesses];
}

- (id)initWithReachability:(Reachability*)reachability
{
    self = [super init];
    
    if(self)
    {
        self.reachability = reachability;
    }
    
    return self;
}

- (void)configureDefaultUrl
{
    NSString *defaultPreference = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultRegionKey];
    
    if(!defaultPreference || defaultPreference.length == 0)
    {
        defaultPreference = kDefaultUrl;
    }
    
    self.defaultURL = defaultPreference;
    
    [[NSUserDefaults standardUserDefaults] setObject:defaultPreference forKey:kDefaultRegionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIView Lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Uncomment to use a custom url
    
    // disable sleep mode
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // hide one of the web views based on whether WKWebView is supported
    if (self.useWkWebView) {
        self.webView.hidden = YES;
        // self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
        self.wkWebView = [[WKWebView alloc] initWithFrame:self.webView.frame];
        [self.view addSubview:self.wkWebView];
        self.wkWebView.hidden = NO;
        self.wkWebView.navigationDelegate = self;
        [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(NSString* jsId, NSError *err){
            NSString *userAgent = jsId;
            [self logValue:userAgent withMessage:@"User Agent"];
        }];
        self.wkWebView.configuration.mediaPlaybackRequiresUserAction = NO;
        self.wkWebView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = YES;
        WKNavigation *wkNav = [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.defaultURL]]];
        
    } else {
        self.wkWebView.hidden = YES;
        NSString *userAgent = [self.webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        
        [self logValue:userAgent withMessage:@"User Agent"];
        [self.webView setMediaPlaybackRequiresUserAction:NO];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.defaultURL]]];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self handleOrientationChange:nil];
}

- (void)processesDidChange:(NSNotification *)note
{
    [self sendProcessList:nil];
}

#pragma mark - UIWebView Delegate

/* Called when the webview is about to load a new url. This is the point which we can catch any custom urls to intercept
 *  and parse. If we we recognize it, the url is not loaded in the webview, and the command/parameter pair is handled
 *  natively. Otherwise, the url is loaded in the webview as normal.
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [self logValue:[request.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] withMessage:@"Received URL Request"];
    
    NSString *requestString = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    NSArray *requestArray = [requestString componentsSeparatedByString:kCustomURLIdentifier];
    
    if ([requestArray count] > 1)
    {
        NSString *requestPrefix = [[requestArray objectAtIndex:0] lowercaseString];
        NSString *requestMsg = ([requestArray count] > 0) ? [requestArray objectAtIndex:1] : @"";
        
        [self webviewMessageKey:requestPrefix value:requestMsg];
        
        return NO;
    }
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (!webView.isLoading)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.lastError = error;
        
        if(error.code >= -2000 && error.code < -1000)
        {
            NSString *htmlFile =[[NSBundle mainBundle] pathForResource:@"load_failed" ofType:@"html"];
            
            NSData *htmlData = [NSData dataWithContentsOfFile:htmlFile];
            
            [webView loadData:htmlData MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:@""]];
            
            // try to exit from the Single App Mode
            NSString *params = @"{\"enable\":\"false\"}";
            [self enableGuidedAccess:params];
        }
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if(!webView.isLoading)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if([webView.request.URL.absoluteString isEqualToString:@"file:///"])
    {
        [self sendJavascript:[NSString stringWithFormat:@"updateTryAgainButton('%@', '%@')", self.defaultURL, self.lastError.localizedDescription] logMessage:nil];
    }
    else
    {
        self.lastError = nil;
    }
}

#pragma mark - WKWebView Delegate

/* Called when the wkWebview is about to load a new url. This is the point which we can catch any custom urls to intercept
 *  and parse. If we we recognize it, the url is not loaded in the webview, and the command/parameter pair is handled
 *  natively. Otherwise, the url is loaded in the webview as normal.
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    [self logValue:[navigationAction.request.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] withMessage:@"Received URL Request"];
    
    NSString *requestString = [[[navigationAction.request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    NSArray *requestArray = [requestString componentsSeparatedByString:kCustomURLIdentifier];
    
    if ([requestArray count] > 1)
    {
        NSString *requestPrefix = [[requestArray objectAtIndex:0] lowercaseString];
        NSString *requestMsg = ([requestArray count] > 0) ? [requestArray objectAtIndex:1] : @"";
        
        [self webviewMessageKey:requestPrefix value:requestMsg];
        
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (!webView.isLoading)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.lastError = error;
        
        if(error.code >= -2000 && error.code < -1000)
        {
            NSString *htmlFile =[[NSBundle mainBundle] pathForResource:@"load_failed" ofType:@"html"];
             
            NSData *htmlData = [NSData dataWithContentsOfFile:htmlFile];
            
            NSString* htmlStr = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
            [webView loadHTMLString:htmlStr baseURL:[NSURL URLWithString:@""]];
            
            // try to exit from the Single App Mode
            NSString *params = @"{\"enable\":\"false\"}";
            [self enableGuidedAccess:params];
        }
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (!webView.isLoading)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.lastError = error;
        
        if(error.code >= -2000 && error.code < -1000)
        {
            NSString *htmlFile =[[NSBundle mainBundle] pathForResource:@"load_failed" ofType:@"html"];
            
            NSData *htmlData = [NSData dataWithContentsOfFile:htmlFile];
            
            NSString* htmlStr = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
            
            [webView loadHTMLString:htmlStr baseURL:[NSURL URLWithString:@""]];
            
            // try to exit from the Single App Mode
            NSString *params = @"{\"enable\":\"false\"}";
            [self enableGuidedAccess:params];
        }
    }
}

- (void)didStartProvisionalNavigation:(WKWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if(!webView.isLoading)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if([webView.URL.absoluteString isEqualToString:@"about:blank"])
    {
        [self sendJavascript:[NSString stringWithFormat:@"updateTryAgainButton('%@', '%@')", self.defaultURL, self.lastError.localizedDescription] logMessage:nil];
    }
    else
    {
        self.lastError = nil;
    }
}

#pragma mark - State Notification Handling

/* The status of guided access has changed, notifies the webview via javascript. */
- (void)guidedAccessStatusChanged:(NSNotification*)note
{
    [self handleGuidedAccessCheck:nil];
}

- (void)voiceOverStatusChanged:(NSNotification*)note
{
    [self handleTextToSpeechCheck:nil];
}

/* The application is entering the backgrounded, notifies the webview via javascript. */
- (void)willEnterBackground:(NSNotification*)note
{
    [self sendJavascript:@"AIRMobile.ntvApplicationEnterBackground()" logMessage:nil];
}

/* The application is returning from being backgrounded, notifies the webview via javascript. */
- (void)willEnterForeground:(NSNotification*)note
{
    if([self.lastError.domain isEqualToString:@"NSURLErrorDomain"] && self.lastError.code >= -2000 && self.lastError.code < -1000)
    {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self.lastError.userInfo objectForKey:@"NSErrorFailingURLStringKey"]]]];
    }
    [self sendJavascript:@"AIRMobile.ntvApplicationReturnFromBackground()" logMessage:nil];
    
    NetworkStatus netStatus = [self.reachability currentReachabilityStatus];
    NSDictionary *params = nil;
    if(netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN)
    {
        params = @{@"status" : @"connected"};
    }
    else
    {
        params = @{@"status" : @"disconnected"};
    }
    
    [self sendJavascript:[NSString stringWithFormat:@"AIRMobile.ntvOnConnectivityChanged('%@')", [NSJSONSerialization JSONStringFromDictionary:params error:nil]] logMessage:nil];
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
    if(!self.webView.isLoading && [self.lastError.domain isEqualToString:@"NSURLErrorDomain"] && self.lastError.code >= -2000 && self.lastError.code < -1000)
    {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self.lastError.userInfo objectForKey:@"NSErrorFailingURLStringKey"]]]];
    }
    else
    {
        Reachability *reachability = [note object];
        NetworkStatus netStatus = [reachability currentReachabilityStatus];
        NSDictionary *params = nil;
        if(netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN)
        {
            params = @{@"status" : @"connected"};
        }
        else
        {
            params = @{@"status" : @"disconnected"};
        }
        
        [self sendJavascript:[NSString stringWithFormat:@"AIRMobile.ntvOnConnectivityChanged('%@')", [NSJSONSerialization JSONStringFromDictionary:params error:nil]] logMessage:nil];
    }
}


#pragma mark - Utilities

- (void)webviewMessageKey:(NSString*)key value:(NSString*)value
{
    key = key.lowercaseString;
    
    if([key isEqualToString:kCMD_Initialize.lowercaseString])
    {
        [self handleInitialize:value];
    }
    else if([key isEqualToString:kCheckGuidedAccessRequest.lowercaseString])
    {
        [self handleGuidedAccessCheck:value];
    }
    else if([key isEqualToString:kCheckNativeProcessesRequest.lowercaseString])
    {
        [self sendProcessList:value];
    }
    else if([key isEqualToString:kCheckTTSRequest.lowercaseString])
    {
        [self handleTextToSpeechCheck:value];
    }
    else if([key isEqualToString:kSetDefaultURL.lowercaseString])
    {
        [self handleSetDefaultURL:value];
    }
    else if([key isEqualToString:kLockOrientation.lowercaseString])
    {
        [self handleLockOrientation:value];
    }
    else if([key isEqualToString:kJavascriptLog.lowercaseString])
    {
        [self handleJavascriptLog:value];
    }
    else if([key isEqualToString:kSpeakText.lowercaseString])
    {
        [self handleTTSEngineRequest:value];
    }
    else if([key isEqualToString:kPauseSpeech.lowercaseString])
    {
        [self handleTTSPauseRequest:value];
    }
    else if([key isEqualToString:kResumeSpeech.lowercaseString])
    {
        [self handleTTSResumeRequest:value];
    }
    else if([key isEqualToString:kStopSpeakingText.lowercaseString])
    {
        [self handleTTSEngineStopRequest:value];
    }
    else if([key isEqualToString:kInitializeAudioRecorder.lowercaseString])
    {
        [self handleInitializeRecorderRequest:value];
    }
    else if([key isEqualToString:kStartAudioCapture.lowercaseString])
    {
        [self handleStartAudioCapture:value];
    }
    else if([key isEqualToString:kEndAudioCapture.lowercaseString])
    {
        [self handleEndAudioCapture:value];
    }
    else if([key isEqualToString:kStartAudioPlayback.lowercaseString])
    {
        [self handlePlayAudio:value];
    }
    else if([key isEqualToString:kStopAudioPlayback.lowercaseString])
    {
        [self handleStopAudioPlayback:value];
    }
    else if([key isEqualToString:kPauseAudioPlayback.lowercaseString])
    {
        [self handlePausePlayback:value];
    }
    else if([key isEqualToString:kResumeAudioPlaback.lowercaseString])
    {
        [self handleResumePlayback:value];
    }
    else if([key isEqualToString:kRequestAudioFileList.lowercaseString])
    {
        [self handleRequestAudioFiles:value];
    }
    else if([key isEqualToString:kRequestAudioFile.lowercaseString])
    {
        [self handleRequestFile:value];
    }
    else if([key isEqualToString:kClearAudioCache.lowercaseString])
    {
        [self handleClearAudioFileCache:value];
    }else if([key isEqualToString:kClearWebCache.lowercaseString])
    {
        [self handleClearWebCache:value];
    }else if ([key isEqualToString:kClearWebCookies.lowercaseString])
    {
        [self handleClearWebCookies:value];
    }else if ([key isEqualToString:kEnableGuidedAccess.lowercaseString])
    {
        [self enableGuidedAccess:value];
    }else if ([key isEqualToString:kTTSSetPitch.lowercaseString])
    {
        [self.ttsEngine ttsSetPitch:value];
    }else if ([key isEqualToString:kTTSSetRate.lowercaseString])
    {
        [self.ttsEngine ttsSetRate:value];
    }else if ([key isEqualToString:kTTSSetVolume.lowercaseString])
    {
        [self.ttsEngine ttsSetVolume:value];
    }else
    {
        [self handleUnsupportedRequest:value];
    }
}

#pragma mark - IBActions

/** Refreshes the webview (diagnostic purposes).
 */
- (IBAction)refresh:(id)sender
{
    [self.webView reload];
}

#pragma mark - AIRMobile API Wrappers

- (NSString*)orientationString
{
    return UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? @"landscape" : @"portrait";
}

/** Send the device info to the webview.
 Executes AIRMobile.ntvOnDeviceReady()
 */
- (void)sendDeviceInfo
{
    NetworkStatus status = self.reachability.currentReachabilityStatus;
    
    NSString *model = [[UIDevice currentDevice] model];
    NSString *os = [[UIDevice currentDevice] systemName];
    NSString *osVer = [[UIDevice currentDevice] systemVersion];
    osVer = [osVer stringByAppendingFormat:@" %@", [[UIDevice currentDevice] osVersionBuild]];
    
    NSString *networkStatus = @"Unknown";
    AIRAppDelegate *appDelegate = (AIRAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(status)
        networkStatus = (status == ReachableViaWiFi || status == ReachableViaWWAN) ? @"connected" : @"disconnected";
    
    NSArray *ttsVoices = [self.ttsEngine availableLanguagePacks];
    
    NSDictionary *deviceInfo = @{@"model" : model,
                                 @"manufacturer" : @"Apple",
                                 @"operatingSystem" : os,
                                 @"operatingSystemVersion" : osVer,
                                 @"apiVersion" : @(kAIRMobileAPIVersion),
                                 @"runningProcesses" : [AIRProcesses currentProcesses],
                                 @"textToSpeech" : @(UIAccessibilityIsVoiceOverRunning()),
                                 @"guidedAccess" : @(UIAccessibilityIsGuidedAccessEnabled()),
                                 @"rootAccess" : @([[UIDevice currentDevice] isJailbroken]),
                                 @"connectivity" : networkStatus,
                                 @"defaultURL" : self.defaultURL ? self.defaultURL : @"",
                                 @"screenResolution" : [UIScreen resolutionString],
                                 @"orientation" : [self orientationString],
                                 @"lockedOrientation" : [self orientationMaskString],
                                 @"ttsEngineStatus" : [self.ttsEngine statusString],
                                 @"ipAddress" : @[[AIRJSCommand getIP]],
                                 @"startTime" : appDelegate.startTime.description,
                                 @"ttsSettings" : [self.ttsEngine ttsSettings],
                                 @"availableTTSLanguages" : [self.ttsEngine availableLanguagePacks],
                                 @"defaultTTSLanguage" : [self.ttsEngine defaultLanguage]};
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:deviceInfo error:nil];
    
    NSString *js = [NSString stringWithFormat:@"AIRMobile.ntvOnDeviceReady('%@')", jsonString];
    
    [self sendJavascript:js logMessage:nil];
}

/**
 *  Execute javascript in the webview
 */
- (NSString*)sendJavascript:(NSString*)javascript logMessage:(NSString*)message
{
    if(![javascript hasPrefix:@"AIRMobile.setAudio"] && [javascript rangeOfString:@"\"updateType\":\"END\""].location == NSNotFound)
    {
        [self logValue:javascript withMessage:message ? message : @"Calling Javascript"];
    }
    else
    {
        [self logValue:@"Sending Audio" withMessage:message ? message : @"..."];
    }
    
    NSString *result = @"";
    if (self.useWkWebView) {
        [self.wkWebView evaluateJavaScript:javascript completionHandler:^(NSString* jsId, NSError *err){
            [self logValue:jsId withMessage:@"Result"];
        }];
    } else {
        result = [self.webView stringByEvaluatingJavaScriptFromString:javascript];
        [self logValue:result withMessage:@"Result"];
    }
    
    return result;
}

- (void)handleUnsupportedRequest:(NSString*)params
{
    NSString *javascript = [AIRJSCommand handleUnsupportedRequest:params];
    
    if(javascript)
        [self sendJavascript:javascript logMessage:nil];
}

- (void)handleInitialize:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSNumber *version = [((NSDictionary*)object) objectForKey:@"version"];
        
        if(version.floatValue >= 1.0f)
        {
            [self sendDeviceInfo];
        }
        else
        {
            [self logValue:version.stringValue withMessage:@"Unsupported Version"];
        }
    }
    else
    {
        [self logValue:@"" withMessage:@"No Version Found"];
    }
}

- (void)handleLockOrientation:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSString *identifier = [((NSDictionary*)object) objectForKey:@"identifier"];
        NSString *requestedOrientation = [[((NSDictionary*)object) objectForKey:@"orientation"] lowercaseString];
        
        if([requestedOrientation isEqualToString:@"portrait"])
        {
            self.orientationMask = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
        }
        else if([requestedOrientation isEqualToString:@"landscape"])
        {
            self.orientationMask = UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
        }
        else
        {
            requestedOrientation = @"none";
            self.orientationMask = UIInterfaceOrientationMaskAll;
        }
        
        NSDictionary *parameters = nil;
        
        if(identifier)
        {
            parameters = @{@"lockedOrientation" : requestedOrientation, @"identifier" : identifier};
        }
        else
        {
            parameters = @{@"lockedOrientation" : requestedOrientation, @"orientation" : [self orientationString]};
        }
        
        NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
        
        [self sendJavascript:[NSString stringWithFormat:@"AIRMobile.ntvOnOrientationLockChanged('%@')", jsonString] logMessage:nil];
    }
}

- (void)handleSetDefaultURL:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
   
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSString *url = [((NSDictionary*)object) objectForKey:@"url"];
        if(url) self.defaultURL = url;
    }
    
    NSString *javascript = [AIRJSCommand handleSetDefaultURL:params];
    
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handleGuidedAccessCheck:(NSString*)params
{
    NSString *javascript = [AIRJSCommand handleGuidedAccessCheck:params];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)enableGuidedAccess:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    __block NSDictionary *parameters = nil;
    
    NSString *osVer = [[UIDevice currentDevice] systemVersion];
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
        NSString *enable = [((NSDictionary*)object) objectForKey:@"enable"];
        
        BOOL isActionEnable = ([enable isEqualToString:@"true"]) ? YES : NO;

        if ([osVer characterAtIndex:0] != '6') {    // call the API for iOS 7+
            UIAccessibilityRequestGuidedAccessSession(isActionEnable, ^(BOOL didSucceed) {
        
                if (identifier) {
                    parameters = @{@"didSucceed" : @(didSucceed), @"enabled" : @(UIAccessibilityIsGuidedAccessEnabled()), kIdentifierKey : identifier};
                } else {
                    parameters = @{@"didSucceed" : @(didSucceed), @"enabled" : @(UIAccessibilityIsGuidedAccessEnabled())};
                }
                NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
                [self sendJavascript:[NSString stringWithFormat:@"AIRMobile.ntvOnEnableGuidedAccessReceived('%@')", jsonString] logMessage:nil];
            });
        } else {    // for iOS 6, the result is always false as this is not a supported feature
            if (identifier) {
                parameters = @{@"didSucceed" : @(NO), @"enabled" : @(UIAccessibilityIsGuidedAccessEnabled()), kIdentifierKey : identifier};
            } else {
                parameters = @{@"didSucceed" : @(NO), @"enabled" : @(UIAccessibilityIsGuidedAccessEnabled())};
            }
            NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
            [self sendJavascript:[NSString stringWithFormat:@"AIRMobile.ntvOnEnableGuidedAccessReceived('%@')", jsonString] logMessage:nil];
        }
    }
}

- (void)handleTextToSpeechCheck:(NSString*)params
{
    NSString *javascript = [AIRJSCommand handleTextToSpeechCheck:params ttsEngine:self.ttsEngine];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handleTTSEngineRequest:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSDictionary *options = nil;
    NSString *identifier = nil;
    NSString *text = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:@"identifier"];
        text = [((NSDictionary*)object) objectForKey:@"textToSpeak"];
        options = [((NSDictionary*)object) objectForKey:@"options"];
    }
    
    [self.ttsEngine speakText:text options:options];
    if(identifier && [self.ttsEngine audioPlayer])
    {
        objc_setAssociatedObject([self.ttsEngine audioPlayer], &kIdentifier, identifier, OBJC_ASSOCIATION_COPY);
    }
    
    [self handleTextToSpeechCheck:nil];
}

- (void)handleTTSPauseRequest:(NSString*)params
{
    [self.ttsEngine pauseSpeech];
    [self handleTextToSpeechCheck:params];
}

- (void)handleTTSResumeRequest:(NSString*)params
{
    [self.ttsEngine resumeSpeech];
    [self handleTextToSpeechCheck:params];
}

- (void)handleInitializeRecorderRequest:(NSString*)params
{
    self.opusAudioRecorder.endCallbackBlock = nil;
    [self.opusAudioRecorder stopRecording];
    
    if(!self.opusAudioRecorder)
    {
        self.opusAudioRecorder = [[AIROpusAudioRecorder alloc] initWithSampleRate:48000];
    }
    
    __weak __typeof(self) weak_self = self;
    
    [self.opusAudioRecorder setStatusCallbackBlock:^(AIROpusAudioRecorder *recorder, long bytes, NSTimeInterval ellapsed){
        [weak_self sendProgress:@(bytes) duration:@(ellapsed)];
    }];
    [self.opusAudioRecorder setEndCallbackBlock:^(AIROpusAudioRecorder *recorder, long bytes, NSTimeInterval ellapsed){
        [weak_self sendFile];
    }];
    
    NSString *javascript = [AIRJSCommand handleInitializeRecorder:params recorder:self.opusAudioRecorder];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handleStartAudioCapture:(NSString*)params
{
    NSString *javascript = [AIRJSCommand handleBeginRecording:params recorder:self.opusAudioRecorder];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handleEndAudioCapture:(NSString*)params
{
    [self.opusAudioRecorder stopRecording];
}

- (void)sendFile
{
    static const float kQualityThreshold = 1500.0f;
    
    NSString *javascript = [AIRJSCommand handleSendAudioFile:self.opusAudioRecorder.filename
                              quality:[self.opusAudioRecorder amplitudeChangeRatio] > kQualityThreshold ? @"good" : @"poor"
                          trackLength:[self.opusAudioRecorder trackLength]];
    
    [self sendJavascript:javascript logMessage:nil];
}

- (void)sendProgress:(NSNumber*)bytes duration:(NSNumber*)duration
{
    NSString *javascript = [AIRJSCommand handleAudioProgress:bytes duration:duration];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handlePlayAudio:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    NSURL *url = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary*)object;
        
        NSDictionary *audioInfo = [dict objectForKey:@"audioInfo"];
        
        NSString *type = [audioInfo objectForKey:@"type"];
        NSString *data = [audioInfo objectForKey:@"data"];
        NSString *filename = [audioInfo objectForKey:@"filename"];
        
        url = [NSURL fileURLWithPath:[AIROpusAudioRecorder fileStoragePath]];
        url = [url URLByAppendingPathComponent:filename ? filename : @"temp.opus"];
        
        if([type isEqualToString:@"filedata"])
        {
            NSData *fileData = [NSData dataFromBase64String:data];
            NSError *error = nil;
            [fileData writeToURL:url options:NSDataWritingAtomic error:&error];
            
            if(error)
            {
                NSLog(@"Error! %@", error);
            }
        }
    }
    
    self.opusAudioPlayer = [[AIROpusAudioPlayer alloc] initWithFileURL:url];
    __weak __typeof(self) weak_self = self;
    [self.opusAudioPlayer setStateChangeBlock:^(AIROpusAudioPlayer* player, AIROpusAudioPlayerStateChange stateChange){
        [weak_self sendAudioPlaybackState:stateChange];
    }];
    
    [self.opusAudioPlayer startPlayback];
}

- (void)sendAudioPlaybackState:(AIROpusAudioPlayerStateChange)state
{
    NSString *status = @"end";
    
    switch (state) {
        case AIROpusAudioPlayerStateChangeEnd:
            status = @"end";
            break;
        case AIROpusAudioPlayerStateChangeError:
            status = @"error";
            break;
        case AIROpusAudioPlayerStateChangePlaying:
            status = @"playing";
            break;
        case AIROpusAudioPlayerStateChangeResumed:
            status = @"resumed";
            break;
        case AIROpusAudioPlayerStateChangePaused:
            status = @"paused";
            break;
        case AIROpusAudioPlayerStateChangeStopped:
            status = @"stopped";
            break;
        default:
            break;
    }
    
    NSDictionary *parameters = @{@"playbackState": status};
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    [self sendJavascript:[NSString stringWithFormat:@"AIRMobile.ntvOnPlaybackStateChanged('%@')", jsonString] logMessage:nil];
}

- (void)handleStopAudioPlayback:(NSString*)params
{
    [self.opusAudioPlayer stop];
}

- (void)handlePausePlayback:(NSString*)params
{
    [self.opusAudioPlayer pause];
}

- (void)handleResumePlayback:(NSString*)params
{
    [self.opusAudioPlayer resume];
}

- (void)airTTSDidFinishPlaying:(AIRTTSEngine *)ttsEngine successfully:(BOOL)successfully
{
    NSString *identifier = objc_getAssociatedObject(ttsEngine.audioPlayer, &kIdentifier);
    
    NSDictionary *dictionary = nil;
    
    if(identifier)
        dictionary = @{@"identifier": identifier};
    
    [self handleTextToSpeechCheck:[NSJSONSerialization JSONStringFromDictionary:dictionary error:nil]];
}

- (void)airTTSSynchronize:(AIRTTSEngine *)ttsEngine word:(NSString*)currentWord location:(NSUInteger)currentLocation length:(NSUInteger)currentLength
{
    // handing TTS synchronize message over to Javascript layer
    NSString *currentLocationStr = [NSString stringWithFormat:@"%d", currentLocation];
    NSString *currentLengthStr = [NSString stringWithFormat:@"%d", currentLength];
    NSDictionary *parameters = @{@"word" : currentWord, @"location" : currentLocationStr, @"length": currentLengthStr};
    NSString *js = [NSString stringWithFormat:@"AIRMobile.ntvOnTTSSynchronized('%@')", [NSJSONSerialization JSONStringFromDictionary:parameters error:nil]];
    
    [self sendJavascript:js logMessage:nil];
    NSLog(@"send message to javascript layer");
    
}

- (void)handleTTSEngineStopRequest:(NSString*)params
{
    [self.ttsEngine stopSpeech];
    [self handleTextToSpeechCheck:params];
}

- (void)handleOrientationChange:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    NSDictionary *parameters = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:@"identifier"];
    }
    
    if(identifier)
    {
        parameters = @{@"orientation" : [self orientationString], @"identifier" : identifier};
    }
    else
    {
        parameters = @{@"orientation" : [self orientationString]};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    [self sendJavascript:[NSString stringWithFormat:@"AIRMobile.ntvOnOrientationChanged('%@')", jsonString] logMessage:nil];
}

- (void)sendProcessList:(NSString*)params
{
    NSString *javascript = [AIRJSCommand handleRequestProcessList:params];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handleRequestAudioFiles:(NSString*)params
{    
    NSString *javascript = [AIRJSCommand handleRequestAudioFiles:params];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handleClearAudioFileCache:(NSString*)params
{
    NSString *javascript = [AIRJSCommand handleClearAudioFileCache:params];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handleRequestFile:(NSString*)params
{
    NSString *javascript = [AIRJSCommand handleAudioFileRequest:params];
    [self sendJavascript:javascript logMessage:nil];
}

- (void)handleJavascriptLog:(NSString*)params
{
    //Do nothing - subclasses may override if they choose to log somewhere
}

- (void)handleClearWebCache:(NSString*)params
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)handleClearWebCookies:(NSString*)params
{
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

- (void)handleGetStartTime:(NSString*)params
{
    AIRAppDelegate *appDelegate = (AIRAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate *date = appDelegate.startTime;
    [self sendJavascript:[NSString stringWithFormat:@"AIRMobile.ntvOnStartTimeReceived('%@')", date.description] logMessage:nil];
    
}

@end
