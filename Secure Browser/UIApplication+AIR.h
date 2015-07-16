//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  UIApplication+AIR.h
//  Secure Browser
//
//  Created by Kenny Roethel on 12/11/12.
//

#import <UIKit/UIKit.h>

@interface UIApplication (AIR)

/** Return YES if the dev mode flag is set in the info plist, false otherwise. */
- (BOOL)isDevelopementBuild;

@end
