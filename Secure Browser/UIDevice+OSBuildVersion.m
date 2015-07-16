//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  UIDevice+OSBuildVersion.m
//  Secure Browser
//
//  Created by Kenny Roethel on 11/8/13.
//

#import "UIDevice+OSBuildVersion.h"
#import <sys/sysctl.h>

@implementation UIDevice (OSBuildVersion)


- (NSString *)osVersionBuild
{
    int mib[2] = {CTL_KERN, KERN_OSVERSION};
    u_int namelen = sizeof(mib) / sizeof(mib[0]);
    size_t bufferSize = 0;
    
    NSString *osBuildVersion = nil;
    
    // Get the size for the buffer
    sysctl(mib, namelen, NULL, &bufferSize, NULL, 0);
    
    u_char buildBuffer[bufferSize];
    int result = sysctl(mib, namelen, buildBuffer, &bufferSize, NULL, 0);
    
    if (result >= 0) {
        osBuildVersion = [[[NSString alloc] initWithBytes:buildBuffer length:bufferSize encoding:NSUTF8StringEncoding] autorelease];
    }

    //Remove non-ascii characters
    NSMutableString *asciiCharacters = [NSMutableString string];
    for (NSInteger i = 32; i < 127; i++)  {
        [asciiCharacters appendFormat:@"%c", i];
    }
    
    NSCharacterSet *nonAsciiCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:asciiCharacters] invertedSet];
    
    osBuildVersion = [[osBuildVersion componentsSeparatedByCharactersInSet:nonAsciiCharacterSet] componentsJoinedByString:@""];
    
    return osBuildVersion;
}

@end
