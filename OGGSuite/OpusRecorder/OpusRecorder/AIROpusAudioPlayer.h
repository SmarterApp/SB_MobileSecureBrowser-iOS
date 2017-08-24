//
//  AIROpusAudioPlayer.h
//  OpusRecorder
//
//  Created by Kenny Roethel on 5/6/13.
//  Copyright (c) 2013 AIR. All rights reserved.
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
