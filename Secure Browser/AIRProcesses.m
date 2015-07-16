//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRProcesses.m
//  Secure Browser
//
//  Created by Kenny Roethel on 5/10/13.
//

#import "AIRProcesses.h"

NSString *const AIRProcessListDidChangeNotification = @"AIRProcessListDidChangeNotification";

@interface AIRProcesses ()

@property (nonatomic, strong) NSArray *processList;
@property (assign, getter = isMonitoring) BOOL monitoring;

@end

@implementation AIRProcesses

#pragma mark - Static

+ (NSArray*)currentProcesses
{
    NSMutableSet *processNames = [[NSMutableSet set] retain];
    NSString *osVer = [[UIDevice currentDevice] systemVersion];
    
    [[[UIDevice currentDevice] runningProcesses] enumerateObjectsUsingBlock:^(id dict, NSUInteger idx, BOOL *stop) {
        
        NSString *processName = [dict objectForKey:kProcessNameKey];
        
        // convert the process name from "MobilePhone" to "FaceTime" for iOS 6 to be consistent with iOS 7
        if (([osVer characterAtIndex:0] == '6') && ([processName isEqualToString:@"MobilePhone"])) {
            processName = @"FaceTime";
        }
        [processNames addObject:processName];
        
    }];
    
    NSArray *processArray = [processNames allObjects];
    [processNames autorelease];
    
    return processArray;
}

#pragma mark - NSObject

- (id)init
{
    self = [super init];

    if(self)
    {
        self.processList = [AIRProcesses currentProcesses];
        self.pollingInterval = 2;
    }
    
    return self;
}

- (void)setPollingInterval:(NSTimeInterval)interval
{
    _pollingInterval = interval;
}

- (void)beginMonitoringProcesses
{
    if(!self.isMonitoring)
    {
        self.monitoring = YES;
        [self updateProcessList];
    }
}

- (void)endMonitoringProcesses
{
    self.monitoring = NO;
}

- (void)updateProcessList
{
    NSArray *current = [AIRProcesses currentProcesses];
    NSArray *last = [self.processList copy];
    
    current = [current sortedArrayUsingSelector:@selector(compare:)];
    last = [last sortedArrayUsingSelector:@selector(compare:)];
    
    if(![current isEqualToArray:last])
    {
        self.processList = [current copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:AIRProcessListDidChangeNotification object:self userInfo:nil];
    }
    
    if(self.isMonitoring)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pollingInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self updateProcessList];
            
        });
    }
}

@end
