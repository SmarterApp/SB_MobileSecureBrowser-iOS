//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIROpusAudioRecorder.h
//  OpusRecorder
//
//  Created by Kenny Roethel on 5/6/13.
//

#import <Foundation/Foundation.h>

typedef enum
{
    AIROpusCallbackTypeNone,
    AIROpusCallbackTypeTime,
    AIROpusCallbackTypeSize
} AIROpusCallbackType;

@class AIROpusAudioRecorder;
typedef void(^AIROpusRecorderStatusBlock)(AIROpusAudioRecorder *recorder, long fileSize, NSTimeInterval duration);
typedef void(^AIROpusRecorderFinishBlock)(AIROpusAudioRecorder *recorder, long fileSize, NSTimeInterval duration);

@interface AIROpusAudioRecorder : NSObject

@property (nonatomic, readonly) float sampleRate;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, readonly) Float32 averageAmplitudeLevel;
@property (nonatomic, readonly) Float32 averageDecibelLevel;

/** A ratio indicating the the frequency which the amplitude of
 audio samples changed significantly in relation the the average amplitude.
 This value can be used as an indicator of audio quality.
 The value returned here represents the current, or last recorded audio samples. */
@property (nonatomic, readonly) Float32 amplitudeChangeRatio;

@property (nonatomic, copy) AIROpusRecorderStatusBlock statusCallbackBlock;
@property (nonatomic, copy) AIROpusRecorderFinishBlock endCallbackBlock;

- (id)initWithSampleRate:(float)sampleRate;
- (void)startRecording:(NSString*)filename sampleRate:(float)sampleRate;
- (void)stopRecording;
- (void)setCallbackFrequency:(int)interval forType:(AIROpusCallbackType)type;
- (void)setRecordingLimit:(int)duration bytes:(long)bytes;
- (NSTimeInterval)trackLength;

+ (NSString*)fileStoragePath;

@end
