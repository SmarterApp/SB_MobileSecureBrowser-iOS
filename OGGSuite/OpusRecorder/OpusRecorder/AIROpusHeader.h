//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  MGOpusHeader.h
//  OpusTesting
//
//  Created by Kenny Roethel on 4/16/13.
//

#import <Foundation/Foundation.h>
#import "opus_header.h"

@interface AIROpusHeader : NSObject

@property (nonatomic, assign) int channels;
@property (nonatomic, assign) int numberOfStreams;
@property (nonatomic, assign) int numberCoupled;
@property (nonatomic, assign) int gain;
@property (nonatomic, assign) int channelMapping;
@property (nonatomic, assign) int inputSampleRate;
@property (nonatomic, assign) int preskip;
@property (nonatomic, assign) int version;

- (id)initWithChannels:(int)channels streams:(int)streams sampleRate:(int)sampleRate preskip:(int)preskip;

- (void)setHeaderData:(OpusHeader*)inHeader;
- (ogg_packet*)newOGGPacket;

@end
