//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRProcesses.h
//  Secure Browser
//
//  Created by Kenny Roethel on 5/10/13.
//

#import <Foundation/Foundation.h>

extern NSString *const AIRProcessListDidChangeNotification;

/**
 *  Convenience class to gather the devices currently running processes.
 */
@interface AIRProcesses : NSObject

@property (assign, nonatomic) NSTimeInterval pollingInterval;

/** Get the currently running processes on the device.
 * @return an array of the current running processes as strings.
 */
+ (NSArray*)currentProcesses;

- (void)beginMonitoringProcesses;
- (void)endMonitoringProcesses;

@end
