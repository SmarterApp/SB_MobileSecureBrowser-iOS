//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  UIScreen+AIR.m
//  Secure Browser
//
//  Created by Kenny Roethel on 5/17/13.
//

#import "UIScreen+AIR.h"

@implementation UIScreen (AIR)

+ (NSString*)resolutionString
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize size = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    
    return NSStringFromCGSize(size);
}

@end
