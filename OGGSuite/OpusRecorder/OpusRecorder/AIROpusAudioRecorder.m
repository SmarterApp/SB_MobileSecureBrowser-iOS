//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIROpusAudioRecorder.m
//  OpusRecorder
//
//  Created by Kenny Roethel on 5/6/13.
//

#import "AIROpusAudioRecorder.h"

#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>

#import <CSIOpusEncoder.h>
#import <AIROpusHeader.h>
#import <AIROpusWriter.h>

#define DBOFFSET -74.0
#define LOWPASSFILTERTIMESLICE .001

static const double kMaxSampleRate = 48000;
static const int kNumberBuffers = 3;
static const double kFrameDuration = 0.04;
static const int kBytesPerFrame = 4096;
static const float kAmplitudeJumpScaleFactor = 3.5f;
static const int kDefaultDuration = 60 * 2; //2 minutes
static const int kDefaultSize = 1024 * 1024; //1 megabyte

static NSString *const kEncoderName = @"AIRiOSEncoder";
// Struct defining recording state
typedef struct
{
    AudioStreamBasicDescription  dataFormat;
    AudioQueueRef                queue;
    AudioQueueBufferRef          buffers[kNumberBuffers];
    AudioFileID                  audioFile;
    SInt64                       currentPacket;
    bool                         recording;
} RecordState;

@interface AIROpusAudioRecorder ()

@property (nonatomic, assign) RecordState recordState;
@property (nonatomic, strong) AIROpusWriter *opusWriter;
@property (nonatomic, strong) CSIOpusEncoder *opusEncoder;

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) long bytesEncoded;
@property (nonatomic, assign) long lastBytesSent;

@property (nonatomic, assign) AIROpusCallbackType callbackType;
@property (nonatomic, assign) long callbackFrequency;

//Audio Metering
@property (nonatomic, assign) Float32 averageAmplitudeLevel;
@property (nonatomic, assign) Float32 averageDecibelLevel;
@property (nonatomic, assign) Float32 amplitudeChangeRatio;

//@property (nonatomic, assign) Float32 avgAmplitude;
@property (nonatomic, assign) long amplitudeJumpCount;
@property (nonatomic, assign) long peakCount;

@property (nonatomic, assign) long kilobyteLimit;
@property (nonatomic, assign) long secondsLimit;

@end

void AudioInputCallback(void * inUserData,
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs);

@implementation AIROpusAudioRecorder

// Takes a filled buffer and writes it to disk, "emptying" the buffer
void AudioInputCallback(void * inUserData,
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs)
{
    AIROpusAudioRecorder *recorder = (__bridge  AIROpusAudioRecorder*)inUserData;
    
    AudioBufferList *bufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList));
    
    bufferList->mNumberBuffers = 1;
    bufferList->mBuffers[0].mDataByteSize = inBuffer->mAudioDataByteSize;
    bufferList->mBuffers[0].mData = inBuffer->mAudioData;
    bufferList->mBuffers[0].mNumberChannels = 1;
    
    [recorder encodeAudio:bufferList timestamp:inStartTime];
    [recorder analyze:bufferList sampleCount:inNumberPacketDescriptions sampleRate:recorder.sampleRate];
    free(bufferList);
    
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

//Rough audio analysis. For each set of audio samples, average the amplitude with the running
//average. Before including the current peak amplitude in the average, check to see if the
//value is increasing by a specific factor or more; if it is, keep track of the occurence.
//When the audio is finished recording, we are left with a count for the number of times
//the amplitude increased and a count of samples. Using these values, we can generate a ratio.
//When this ratio is very low, it is likely no noise, ambient noise, or too much noise to
//make out voice data. When it is higher, the mic has picked up significant variations if the noise
//was coming from a voice, it is likely clear enough to hear.
- (void)analyze:(AudioBufferList *)ioData sampleCount:(int)count sampleRate:(double)sampleRate
{
    SInt16* samples = (SInt16*)(ioData->mBuffers[0].mData);
    
    Float32 decibels = DBOFFSET; 
    Float32 currentFilteredValueOfSampleAmplitude, previousFilteredValueOfSampleAmplitude;
    Float32 peakValue = DBOFFSET; 
    Float32 peakAmplitude = 0;
    
    int iterationCount = kMaxSampleRate / sampleRate;
    count = count / iterationCount;
    int base = 0;
    
    for (int j = 0; j < iterationCount; j++)
    {
        base = count * j;
        
        for (int i = 0; i < count; i++) {
            
            Float32 absoluteValueOfSampleAmplitude = abs(samples[i + base]);
            Float32 amplitudeToConvertToDB;
            
            {
                currentFilteredValueOfSampleAmplitude = LOWPASSFILTERTIMESLICE * absoluteValueOfSampleAmplitude + (1.0 - LOWPASSFILTERTIMESLICE) * previousFilteredValueOfSampleAmplitude;
                previousFilteredValueOfSampleAmplitude = currentFilteredValueOfSampleAmplitude;
                amplitudeToConvertToDB = currentFilteredValueOfSampleAmplitude;
            }
            
            Float32 sampleDB = [self decibelFromAmplitude:amplitudeToConvertToDB];
            
            if((sampleDB == sampleDB) && (sampleDB != -DBL_MAX))
            {
                if(sampleDB > peakValue)
                {
                    peakValue = sampleDB;
                    peakAmplitude = amplitudeToConvertToDB;
                }
                decibels = peakValue;
            }
        }
        
        self.peakCount++;
        
        if(peakAmplitude > (self.averageAmplitudeLevel * kAmplitudeJumpScaleFactor) && self.averageAmplitudeLevel > 0)
        {
            self.amplitudeJumpCount += 1;
        }
        
        self.averageAmplitudeLevel = ((self.averageAmplitudeLevel + peakAmplitude) / ((self.averageAmplitudeLevel > 0) ? 2 : 1));
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"audioPeak" object:nil userInfo:@{@"decibel" : @(decibels), @"amplitude" : @(peakAmplitude)}];
    }
}

- (Float32)decibelFromAmplitude:(Float32)amplitudeToConvertToDB
{
    return 20.0 * log10(amplitudeToConvertToDB) + DBOFFSET;
}

- (id)init
{
    self = [super init];
    
    if(self)
    {
        _sampleRate = kMaxSampleRate;
        self.secondsLimit = 10;
        self.kilobyteLimit = 5000000;
    }
    
    return self;
}

- (id)initWithSampleRate:(float)sampleRate
{
    self = [super init];
    
    if(self)
    {
        _sampleRate = sampleRate;
        self.secondsLimit = 10;
        self.kilobyteLimit = 5000000;
    }
    
    return self;
}

- (void)dealloc
{
    AudioQueueStop(_recordState.queue, true);
    AudioQueueDispose(_recordState.queue, true);
}

- (void)setRecordingLimit:(int)duration bytes:(long)bytes
{
    self.secondsLimit = duration > 0 ? MAX(duration, 1) : 120;
    self.kilobyteLimit = bytes > 0 ? bytes : kDefaultSize;
}

- (void)setupAudioFormat:(AudioStreamBasicDescription*)format sampleRate:(float)rate
{
	format->mSampleRate = rate;
	format->mFormatID = kAudioFormatLinearPCM;
	format->mFramesPerPacket = 1;
	format->mChannelsPerFrame = 1;
	format->mBytesPerFrame = 2;
	format->mBytesPerPacket = 2;
	format->mBitsPerChannel = 16;
	format->mReserved = 0;
	format->mFormatFlags = kAudioFormatFlagsCanonical;
}

- (void)startRecording:(NSString*)filename sampleRate:(float)sampleRate
{
    self.filename = filename;
    self.lastBytesSent = 0;
    self.bytesEncoded = 0;
    self.amplitudeJumpCount = 0;
    self.averageAmplitudeLevel = 0;
    self.peakCount = 0;
    
    _sampleRate = sampleRate > 0 ? sampleRate : kMaxSampleRate;
    [self setupAudioFormat:&_recordState.dataFormat sampleRate:_sampleRate];
    
    int bytesPerFrame = kBytesPerFrame;
    
    self.opusEncoder = [[CSIOpusEncoder alloc] initWithSampleRate:_recordState.dataFormat.mSampleRate
                                                         channels:1
                                                    frameDuration:kFrameDuration error:nil];
    
    AIROpusHeader *header = [[AIROpusHeader alloc] initWithChannels:1
                                                            streams:1
                                                         sampleRate:_recordState.dataFormat.mSampleRate
                                                            preskip:315];
    
    self.opusWriter = [[AIROpusWriter alloc] initWithFileHeader:header
                                                       fileName:filename
                                                    encoderName:kEncoderName];
    
    self.opusWriter.sampleRate = _recordState.dataFormat.mSampleRate;
    [self.opusWriter prepare];
    
    AudioSessionInitialize(NULL,
                           NULL,
                           nil,
                           (__bridge  void *)(self)
                           );
    
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(sessionCategory),
                            &sessionCategory
                            );
    
    AudioSessionSetActive(true);
    
    OSStatus status = AudioQueueNewInput(&_recordState.dataFormat,
                                         AudioInputCallback,
                                         (__bridge void*)self,
                                         CFRunLoopGetCurrent(),
                                         kCFRunLoopCommonModes,
                                         0,
                                         &_recordState.queue);
    
    if(status == noErr)
    {
        for (int i = 0; i < kNumberBuffers; i++)
        {
            AudioQueueAllocateBuffer(_recordState.queue, bytesPerFrame, &_recordState.buffers[i]);
            AudioQueueEnqueueBuffer (_recordState.queue, _recordState.buffers[i], 0, NULL);
        }
        
        status = AudioQueueStart(_recordState.queue, NULL);
        
        if (status == noErr)
        {
            self.startTime = [NSDate date];
            _recordState.recording = YES;
            
            if(self.callbackType == AIROpusCallbackTypeTime)
            {
                [self performSelector:@selector(sendCallback) withObject:nil afterDelay:self.callbackFrequency];
            }
        }
        else
        {
            NSLog(@"Error Starting Queue %li", status);
        }
    }
    else
    {
        NSLog(@"Error creating queue %li", status);
    }
}

- (BOOL)isRecordingLimitExceeded
{
    BOOL exceeded = NO;
    
    NSTimeInterval ellapsed = [[NSDate date] timeIntervalSinceDate:self.startTime];
    
    if(self.kilobyteLimit > 0 && self.bytesEncoded > self.kilobyteLimit)
    {
        exceeded = YES;
    }
    else if(self.secondsLimit > 0 && ellapsed > self.secondsLimit)
    {
        exceeded = YES;
    }
    
    return exceeded;
}

- (void)stopRecording
{
    if(_recordState.recording)
        [self performSelector:@selector(recordingEnded) withObject:nil afterDelay:.5];
    
    _recordState.recording = NO;
}

- (void)recordingEnded
{
    if(self.endCallbackBlock)
    {
        self.endCallbackBlock(self, self.bytesEncoded, [[NSDate date] timeIntervalSinceDate:self.startTime]);
    }
}

- (void)encodeAudio:(AudioBufferList *)data timestamp:(const AudioTimeStamp *)timestamp
{
    @synchronized(self)
    {
        if(self.opusEncoder)
        {
            [self writeEncodedAudioSamples:[self.opusEncoder encodeBufferList:data]];
            if(self.recordState.recording == NO)
                self.opusEncoder  = nil;
        }
    }
}

- (void)writeEncodedAudioSamples:(NSArray*)encodedSamples
{
    [encodedSamples enumerateObjectsUsingBlock:^(NSData *obj, NSUInteger idx, BOOL *stop) {
        
        self.bytesEncoded += obj.length;
        
        if(self.callbackType == AIROpusCallbackTypeSize)
        {
            if(self.bytesEncoded - self.lastBytesSent >= self.callbackFrequency)
            {
                [self sendCallback];
            }
        }
        
        BOOL lastFrame = !_recordState.recording && idx == encodedSamples.count-1;
        
        [self.opusWriter writeEncodedData:obj encodedSampleCount:self.opusEncoder.samplesPerFrame streamIndex:0 lastFrame:lastFrame];
        
        if(lastFrame)
        {
            AudioQueueStop(_recordState.queue, true);
            AudioQueueDispose(_recordState.queue, true);
        }
    }];
    
    if(_recordState.recording && [self isRecordingLimitExceeded])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopRecording];
        });
        
    }
}

- (void)setCallbackFrequency:(int)interval forType:(AIROpusCallbackType)type
{
    self.callbackFrequency = interval;
    self.callbackType = type;
}

- (void)sendCallback
{
    self.lastBytesSent = self.bytesEncoded;
    
    if(self.callbackType != AIROpusCallbackTypeNone && self.statusCallbackBlock && _recordState.recording)
    {
        NSTimeInterval ellapsed = [[NSDate date] timeIntervalSinceDate:self.startTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusCallbackBlock(self, self.bytesEncoded, ellapsed);
        });
        
        if(self.callbackType == AIROpusCallbackTypeTime && _recordState.recording)
            [self performSelector:@selector(sendCallback) withObject:nil afterDelay:self.callbackFrequency];
    }
}

- (NSTimeInterval)trackLength
{
    return [[NSDate date] timeIntervalSinceDate:self.startTime];
}

- (float)amplitudeChangeRatio
{
    static const int kScaleFactor = 100000; //easier to read large numbers than really small decimals
    return (self.amplitudeJumpCount/(double)self.peakCount) * kScaleFactor;
}

+ (NSString*)fileStoragePath
{
    return [AIROpusWriter fileStoragePath];
}

@end
