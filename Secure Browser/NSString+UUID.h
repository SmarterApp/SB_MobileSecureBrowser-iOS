//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  NSString+UUID.h
//  Secure Browser
//
//  Created by Kenny Roethel on 5/10/13.
//

#import <Foundation/Foundation.h>

/**
 *  String extension to provided convenience unique identifier method.
 */
@interface NSString (UUID)

/** Generate a random unique identifier.
 * @return a new random unique identifier string.
 */
+ (NSString *)UUID;

@end
