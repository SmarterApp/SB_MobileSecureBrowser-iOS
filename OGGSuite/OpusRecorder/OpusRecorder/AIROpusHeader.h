//
//  MGOpusHeader.h
//  OpusTesting
//
//  Created by Kenny Roethel on 4/16/13.
//  Copyright (c) 2013 Mindgrub Technologies. All rights reserved.
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
