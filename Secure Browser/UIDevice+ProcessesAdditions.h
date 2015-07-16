//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  UIDevice+ProcessesAdditions.h
//  Secure Browser
//
//  Created by Kenny Roethel on 11/21/12.
//

#import <UIKit/UIKit.h>

extern NSString *const kProcessNameKey;
extern NSString *const kProcessIDKey;

@interface UIDevice (ProcessesAdditions)

/** Fetch a list of currently running processes on the device. */
- (NSArray *)runningProcesses;

/** Attempt to detect if the device is jailbroken. 
 *  returns YES if detected, NO otherwise. */
- (BOOL)isJailbroken;

@end
