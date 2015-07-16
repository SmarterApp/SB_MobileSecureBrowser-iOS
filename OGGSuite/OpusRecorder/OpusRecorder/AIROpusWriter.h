//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  OpusWriter.h
//  OpusTesting
//
//  Created by Kenny Roethel on 4/16/13.
//
//  Wraps the stream writing logic for opus/ogg in an object oriented way.
//
//  Usage:
//
//  OpusWriter *writer = [[OpusWriter alloc] initWithFileHeader:header fileName:@"myfile.opus" encoderName:@"name app name"];
//  [writer prepare];
//
//  [self.encodedFrames enumerateObjectsUsingBlock:^(id data, int idx, BOOL *stop){
//
//      [writer writeEncodedData:data encodedSampleCount:samplesPerFrame
//                                                serial:streamId
//                                             lastFrame:idx == weak_self.encodedFrames.count-1];
//
//  }];
//
//  Because the writer actively writes the encoded bytes, the object is stateful and a proper order
//  of method calls must be maintained.
//  - Prepare
//  - Write Encoded Data
//  - Finish

#import <Foundation/Foundation.h>
#import "AIROpusHeader.h"

@interface AIROpusWriter : NSObject

@property (nonatomic, assign) float sampleRate;

- (id)initWithFileHeader:(AIROpusHeader*)header
                fileName:(NSString*)fileName
             encoderName:(NSString*)encoderName;

- (void)prepare;

- (void)writeEncodedData:(NSData*)encodedSamples
      encodedSampleCount:(int)sampleCount
             streamIndex:(int)streamIndex
               lastFrame:(BOOL)isLastFrame;

- (void)finish;

- (long)createNewSerial;

- (void)endStream:(int)index;

+ (NSString*)fileStoragePath;

@end
