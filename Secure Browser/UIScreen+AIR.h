//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  UIScreen+AIR.h
//  Secure Browser
//
//  Created by Kenny Roethel on 5/17/13.
//

#import <UIKit/UIKit.h>

/**
 *  UIScreen extension for getting resolution.
 */
@interface UIScreen (AIR)

/** Get the screen resolution as a string.
 @return the screen resolution
 */
+ (NSString*)resolutionString;

@end
