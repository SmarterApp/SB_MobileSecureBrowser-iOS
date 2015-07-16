//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  UIColor+AIR.h
//  Secure Browser
//
//  Created by Kenny Roethel on 12/6/12.
//

#import <UIKit/UIKit.h>

/**
 *  Color extension for easy access to log level UI colors.
 */
@interface UIColor (AIR)

/** Convience method to get the log color for a given type.
 *  @param type the type to select a color for. one of:
 *  "info"
 *  "error"
 *  "warn"
 *  "debug"
 */
+ (UIColor*)colorForLogType:(NSString*)type;

@end
