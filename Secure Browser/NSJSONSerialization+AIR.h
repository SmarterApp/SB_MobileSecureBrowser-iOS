//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  NSJSONSerialization+AIR.h
//  Secure Browser
//
//  Created by Kenny Roethel on 12/6/12.
//

#import <Foundation/Foundation.h>

/**
 *  NSJSONSerialization extension that make conversions simple one liners.
 */
@interface NSJSONSerialization (AIR)

/** Convenience method to generate a json string from a dictionary. 
 * @param dictionary the dictionary to convert.
 * @param error an error to fill in if occurs.
 */
+ (NSString*)JSONStringFromDictionary:(NSDictionary*)dictionary error:(NSError**)error;

/** Convenience method to generate a json object (eg. dictionary) from a json string. 
 * @param jsonString the json string to convert.
 */
+ (NSObject*)JSONObject:(NSString*)jsonString;

@end
