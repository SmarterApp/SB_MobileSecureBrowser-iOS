//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  NSJSONSerialization+AIR.m
//  Secure Browser
//
//  Created by Kenny Roethel on 12/6/12.
//

#import "NSJSONSerialization+AIR.h"

@implementation NSJSONSerialization (AIR)

+ (NSString*)JSONStringFromDictionary:(NSDictionary*)dictionary error:(NSError**)error
{
    if(dictionary)
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:error];
        
        return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    return nil;
}

+ (NSObject*)JSONObject:(NSString*)jsonString
{
    NSError *error = nil;
    
    NSObject *obj = nil;
    
    if(jsonString)
        obj = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
    
    if(error)
    {
        NSLog(@"JSON parse error %@", error);
    }
    
    return obj;
}

@end
