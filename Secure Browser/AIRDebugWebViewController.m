//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRDebugWebViewController.m
//  Secure Browser
//
//  Created by Kenny Roethel on 12/10/12.
//

#import "AIRDebugWebViewController.h"
#import "NSJSONSerialization+AIR.h"
#import "UIColor+AIR.h"

static NSString *const kDefaultUrl = @"https://browser.smarterapp.org/landing/";

@interface AIRDebugWebViewController () <UITextFieldDelegate>

@property (nonatomic, retain) IBOutlet UITextView *consoleView;
@property (nonatomic, retain) IBOutlet UITextView *jsConsoleView;
@property (nonatomic, retain) IBOutlet UITextView *consoleWrapper;

@property (nonatomic, retain) IBOutletCollection(UIBarButtonItem) NSArray *leftNavButtons;
@property (nonatomic, retain) IBOutletCollection(UIBarButtonItem) NSArray *rightNavButtons;

@property (nonatomic, retain) IBOutlet UIProgressView *meter;

@end

@implementation AIRDebugWebViewController

#pragma mark - NSObject

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    nibNameOrNil = @"AIRWebViewController_debug";
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"audioPeak" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        NSNumber *amp = [note.userInfo objectForKey:@"amplitude"];
        
        float val = [amp floatValue] / 500;
    
        [self.meter setProgress:val animated:YES];
        
    }];
    return self;
}

- (void)dealloc
{
    self.consoleView = nil;
    self.jsConsoleView = nil;
    self.consoleWrapper = nil;
    
    self.leftNavButtons = nil;
    self.rightNavButtons = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.consoleView.text = nil;
    self.jsConsoleView.text = nil;
    
    [self logValue:@"Received Memory Warning, clearing console" withMessage:@"Device" textView:self.consoleView color:[UIColor redColor]];
}

#pragma mark - UIView Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Development Mode";
    
    BOOL showNavigationItems = YES;
    
    if(showNavigationItems) //For internal testing
    {
        UITextField *field = [[[UITextField alloc] initWithFrame:CGRectMake(0, 0, 250, 25)] autorelease];
        field.backgroundColor = [UIColor whiteColor];
        field.borderStyle = UITextBorderStyleBezel;
        field.returnKeyType = UIReturnKeyGo;
        field.keyboardType = UIKeyboardTypeURL;
        field.delegate = self;
        field.font = [UIFont systemFontOfSize:12];
        field.placeholder = @"enter custom url";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        
        UIBarButtonItem *homeButton = [[[UIBarButtonItem alloc] initWithTitle:@"Test Page" style:UIBarButtonItemStyleBordered target:self action:@selector(loadTestPage:)] autorelease];
        UIBarButtonItem *addressButton = [[[UIBarButtonItem alloc] initWithCustomView:field] autorelease];
        UIBarButtonItem *meterButton = [[UIBarButtonItem alloc] initWithCustomView:self.meter];
        
        self.navigationItem.leftBarButtonItems = @[homeButton, addressButton];
        
        NSMutableArray *rightNav = [NSMutableArray arrayWithArray:self.rightNavButtons];
        [rightNav addObject:meterButton];
        self.navigationItem.rightBarButtonItems = rightNav;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.consoleView = nil;
    self.jsConsoleView = nil;
    self.consoleWrapper = nil;
    
    self.leftNavButtons = nil;
    self.rightNavButtons = nil;
}

#pragma mark - Actions

- (IBAction)loadTestPage:(id)sender
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://clients.mindgrub.com/AIR/"]]];
}

- (void)handleJavascriptLog:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSString *type = [((NSDictionary*)object) objectForKey:@"type"];
        NSString *value = [((NSDictionary*)object) objectForKey:@"value"];
        
        UIColor *color = [UIColor colorForLogType:type];
        
        [self logValue:value withMessage:type textView:self.jsConsoleView color:color];
    }
    else
    {
        [self logValue:params withMessage:@"console" textView:self.jsConsoleView];
    }
}

#pragma mark - Console Logging

/* Log a message to the simulated console */
- (void)logMessage:(NSAttributedString*)message textView:(UITextView*)textView
{
    static const int truncateLength = 8000;
    
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithAttributedString:message];
    
    NSMutableAttributedString *curr = [textView.attributedText mutableCopy];
    [curr appendAttributedString:s];
    
    if(curr.length > truncateLength)
    {
        
        [curr deleteCharactersInRange:NSMakeRange(0, curr.length-truncateLength)];
    }
    
    textView.attributedText = curr;
    [curr release];
    [s release];
    
    [textView scrollRectToVisible:CGRectMake(0, textView.contentSize.height-2, 1, 1) animated:YES];
}

/* Log a value/message pair to the simulated console. */
- (void)logValue:(NSString*)value withMessage:(NSString*)message textView:(UITextView*)textView color:(UIColor*)color
{
    NSString *msg = [NSString stringWithFormat:@"%@: %@", message, value];
    
    NSMutableAttributedString * string = [[[NSMutableAttributedString alloc] initWithString:msg] autorelease];
    [string addAttribute:NSForegroundColorAttributeName value:color range:[msg rangeOfString:value]];
    
    [self logMessage:string textView:textView];
}

/* Log a value/message pair to the simulated console. */
- (void)logValue:(NSString*)value withMessage:(NSString*)message textView:(UITextView*)textView
{
    [self logValue:value withMessage:message textView:textView color:[UIColor blueColor]];
}

- (void)logValue:(NSString*)value withMessage:(NSString*)message
{
    [self logValue:value withMessage:message textView:self.consoleView];
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    NSString *urlString = textField.text;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    
    return YES;
}

#pragma mark - IBActions

/* Simulates toggling guided access to the on state (diagnostic purposes). */
- (IBAction)simulateGuidedAccessON:(id)sender
{
    NSDictionary *parameters = @{@"enabled" : @(YES)};
    
    NSString *js = [NSString stringWithFormat:@"AIRMobile.ntvOnGuidedAccessEnabled('%@')", [NSJSONSerialization JSONStringFromDictionary:parameters error:nil]];
    
    [self sendJavascript:js logMessage:nil];
}

/* Simulates toggling guided access to the off state (diagnostic purposes). */
- (IBAction)simulateGuidedAccessOFF:(id)sender
{
    NSDictionary *parameters = @{@"enabled" : @(NO)};
    
    NSString *js = [NSString stringWithFormat:@"AIRMobile.ntvOnGuidedAccessEnabled('%@')", [NSJSONSerialization JSONStringFromDictionary:parameters error:nil]];
    
    [self sendJavascript:js logMessage:nil];
}

- (IBAction)clearConsole:(id)sender
{
    self.consoleView.text = nil;
}

- (IBAction)clearJSConsole:(id)sender
{
    self.jsConsoleView.text = nil;
}

/* Resize contents as user drags */
- (IBAction)handleVerticalPan:(UIPanGestureRecognizer*)recognizer
{
    CGPoint loc = [recognizer locationInView:self.view];
    
    if(loc.y < recognizer.view.frame.size.height)
    {
        loc.y = recognizer.view.frame.size.height;
    }
    if(loc.y > self.view.frame.size.height - recognizer.view.frame.size.height)
    {
        loc.y = self.view.frame.size.height - recognizer.view.frame.size.height;
    }
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - (self.view.frame.size.height -loc.y) - recognizer.view.frame.size.height/2);
    }
    
    recognizer.view.frame = CGRectMake(0, loc.y-recognizer.view.frame.size.height/2, self.view.frame.size.width, recognizer.view.frame.size.height);
    
    self.consoleWrapper.frame = CGRectMake(0, loc.y + recognizer.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height - loc.y - recognizer.view.frame.size.height/2);
}

@end
