//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  WKWebView+AIR.h
//  Secure Browser
//
//  Created by Han Yu on 10/15/14.
//

#import <WebKit/WebKit.h>

/**
 *  WKWebView extension for disable text selection menu options.
 */
@interface WKWebView (AIR)

/** Get the screen resolution as a string.
 @return the screen resolution
 */
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;

@end
