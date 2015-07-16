//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIROpusAudioPlayer.h
//  OpusRecorder
//
//  Created by Kenny Roethel on 5/6/13.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>

typedef enum {
    AIROpusAudioPlayerStateChangeEnd,
    AIROpusAudioPlayerStateChangePlaying,
    AIROpusAudioPlayerStateChangePaused,
    AIROpusAudioPlayerStateChangeResumed,
    AIROpusAudioPlayerStateChangeStopped,
    AIROpusAudioPlayerStateChangeError
}AIROpusAudioPlayerStateChange;

@class CSIOpusDecoder, AIROpusAudioPlayer;

typedef void(^AIROpusAudioPlayerStateChangeBlock)(AIROpusAudioPlayer *player, AIROpusAudioPlayerStateChange stateChange);

@interface AIROpusAudioPlayer : NSObject

@property (nonatomic, copy) AIROpusAudioPlayerStateChangeBlock stateChangeBlock;
@property (nonatomic, readonly, strong) CSIOpusDecoder *opusDecoder;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL isPaused;

- (id)initWithFileURL:(NSURL*)url;

- (void)startPlayback;
- (void)stop;
- (void)pause;
- (void)resume;


@end
