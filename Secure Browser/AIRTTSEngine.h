//
//  AIRTTSEngine.h
//  iPhone Text To Speech based on Flite
//
//  Copyright (c) 2010 Sam Foster
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Author: Sam Foster <samfoster@gmail.com> <http://cmang.org>
//  Copyright 2010. All rights reserved.
//
//  Modified 6/2013 Kenny Roethel

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AIRTTSEngine;
@protocol AIRTTSDelegate <NSObject>

@optional

- (void)airTTSDidFinishPlaying:(AIRTTSEngine*)ttsEngine successfully:(BOOL)successfully;
- (void)airTTSDecodeErrorDidOccur:(AIRTTSEngine*)ttsEngine error:(NSError*)error;
- (void)airTTSSynchronize:(AIRTTSEngine*)ttsEngine word:(NSString*)currentWord location:(NSUInteger)currentLocation length:(NSUInteger)currentLength;

@end

@interface AIRTTSEngine : NSObject 

@property (nonatomic, weak) id<AIRTTSDelegate> delegate;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL isPaused;
@property (nonatomic, strong, readonly) AVAudioPlayer *audioPlayer;

// - Playback

-(void)speakText:(NSString *)text;
-(void)speakText:(NSString *)text options:(NSDictionary*)options;
-(void)stopSpeech;
-(void)pauseSpeech;
-(void)resumeSpeech;

// - Configuration
- (AVAudioPlayer*)audioPlayer;
- (NSString*)statusString;

- (NSMutableArray*)availableLanguagePacks;
- (NSString*)defaultLanguage;

- (NSDictionary*)ttsSettings;
- (BOOL)ttsSetPitch:(NSString *)pitch;
- (BOOL)ttsSetRate:(NSString *)rate;
- (BOOL)ttsSetVolume:(NSString *)volume;

@end
