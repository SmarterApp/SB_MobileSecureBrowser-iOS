//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRSplashViewController.m
//  Secure Browser
//
//  Created by Kenny Roethel on 11/15/12.
//

#import "AIRSplashViewController.h"

@interface AIRSplashViewController ()

@property (nonatomic, retain) IBOutlet UILabel *messageLabel;
@property (nonatomic, retain) IBOutlet UIView *overlayView;

@end

@implementation AIRSplashViewController

#pragma mark - NSObject

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self)
    {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
        
        if(!_reachability)
        {
            _reachability = [[Reachability reachabilityForInternetConnection] retain];
            [_reachability startNotifier];
        }
    }
    
    return self;
}

- (id)initWithReachability:(Reachability*)reachability delegate:(id<AIRSpashViewControllerDelegate>)delegate
{
    self = [super init];
    
    if(self)
    {
        self.delegate = delegate;
        
        if(_reachability != reachability)
        {
            [_reachability release];
            _reachability = [reachability retain];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.delegate = nil;
    
    self.reachability = nil;
    self.messageLabel = nil;
    self.overlayView = nil;
    
    [super dealloc];
}

#pragma mark - UIView Lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self checkStatus];
}

#pragma mark - Notifications

- (void)reachabilityChanged:(NSNotification*)note
{
    [self checkStatus];
}

#pragma mark - Setters

- (void)setReachability:(Reachability *)reachability
{
    if(_reachability != reachability)
    {
        [_reachability release];
        _reachability = [reachability retain];
        
        [self checkStatus];
    }
}

#pragma mark - Utililty

- (void)checkStatus
{
    NetworkStatus netStatus = [_reachability currentReachabilityStatus];
    BOOL connectionRequired= [_reachability connectionRequired];
    NSString* statusString= @"";
    BOOL dismiss = NO;
    
    switch (netStatus)
    {
        case NotReachable:
        {
            statusString = @"No Internet Connection, please check your network settings and try again.";
            //Minor interface detail- connectionRequired may return yes, even when the host is unreachable.  We cover that up here...
            connectionRequired= NO;
            break;
        }
        case ReachableViaWWAN:
        {
            dismiss = YES;
            break;
        }
        case ReachableViaWiFi:
        {
            dismiss = YES;
            break;
        }
    }
    if(connectionRequired)
    {
        statusString= [NSString stringWithFormat: @"%@, Connection Required", statusString];
    }
    
    if(dismiss)
    {
        int64_t delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            if(_delegate && [_delegate respondsToSelector:@selector(splashViewControllerDidComplete)])
            {
                [_delegate splashViewControllerDidComplete];
            }
            
        });
    }
    else
    {
        if(self.overlayView.hidden)
        {
            self.overlayView.alpha = 0;
            self.overlayView.hidden = NO;
        }
       
        [UIView animateWithDuration:.5 animations:^{
            
            self.overlayView.alpha = 1;
        
        }];
        
        self.messageLabel.text = statusString;
    }
}

@end
