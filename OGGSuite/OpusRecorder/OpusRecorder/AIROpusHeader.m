//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  MGOpusHeader.m
//  OpusTesting
//
//  Created by Kenny Roethel on 4/16/13.
//

#import "AIROpusHeader.h"
#import "opus_header.h"

static const int kDefaultChannelCount = 1;
static const int kDefaultStreamCount = 1;
static const int kDefaultCoupledCount = 0;
static const int kDefaultMapping = 0;
static const int kDefaultSampleRate = 0;
static const int kDefaultPreskip = 315;
static const int kDefaultVersion = 1;

@implementation AIROpusHeader

- (id)init
{
    self = [super init];
    
    if(self)
    {
        self.channels = kDefaultChannelCount;
        self.numberOfStreams = kDefaultStreamCount;
        self.numberCoupled = kDefaultCoupledCount;
        self.channelMapping = kDefaultMapping;
        self.inputSampleRate = kDefaultSampleRate;
        self.preskip = kDefaultPreskip;
        self.version = kDefaultVersion;
    }
    
    return self;
}

- (id)initWithChannels:(int)channels streams:(int)streams sampleRate:(int)sampleRate preskip:(int)preskip
{
    self = [super init];
    
    if(self)
    {
        self.channels = channels;
        self.numberOfStreams = streams;
        self.inputSampleRate = sampleRate;
        self.preskip = preskip;
    }
    
    return self;
}

- (OpusHeader*)newOpusHeader
{
    OpusHeader *inHeader = malloc(sizeof(OpusHeader));
    
    [self setHeaderData:inHeader];
    
    return inHeader;
}

- (void)setHeaderData:(OpusHeader*)inHeader
{
    inHeader->channels = self.channels;
    inHeader->nb_streams = self.numberOfStreams;
    inHeader->nb_coupled = self.numberCoupled;
    inHeader->gain = self.gain;
    inHeader->channel_mapping = self.channelMapping;
    inHeader->input_sample_rate = self.inputSampleRate;
    inHeader->preskip = self.preskip;
    inHeader->version = self.version;
}

- (ogg_packet*)newOGGPacket
{
    ogg_packet *inPacket = malloc(sizeof(ogg_packet));
    
    OpusHeader *header = [self newOpusHeader];
    
    unsigned char *header_data = malloc(sizeof(char)*100);
    int packet_size = opus_header_to_packet(header, header_data, 100);
    
    free(header);
    
    inPacket->packet=header_data;
    inPacket->bytes=packet_size;
    inPacket->b_o_s=1;
    inPacket->e_o_s=0;
    inPacket->granulepos=0;
    inPacket->packetno=0;
    
    return inPacket;
}

@end
