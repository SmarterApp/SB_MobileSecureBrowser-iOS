//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  UIColor+AIR.m
//  Secure Browser
//
//  Created by Kenny Roethel on 12/6/12.
//

#import "UIColor+AIR.h"

@implementation UIColor (AIR)

+ (UIColor*)colorForLogType:(NSString*)type
{
    UIColor *color = [UIColor blueColor];
    
    if([type isEqualToString:@"error"])
    {
        color = [UIColor redColor];
    }
    else if([type isEqualToString:@"warn"])
    {
        color = [UIColor colorWithRed:1 green:.8 blue:0 alpha:1];
    }
    else if([type isEqualToString:@"debug"])
    {
        color = [UIColor brownColor];
    }
    
    return color;
}

@end
