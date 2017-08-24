//
//  AIROpusAudioPlayer.m
//  OpusRecorder
//
//  Created by Kenny Roethel on 5/6/13.
//  Copyright (c) 2013 AIR. All rights reserved.
//

#import "AIROpusAudioPlayer.h"

#import "CSIOpusDecoder.h"
#import "oggz/oggz.h"
#import <AVFoundation/AVFoundation.h>

static const int kNumberBuffers = 3;
static const double kFrameDuration = 0.04;
static const double kSampleRate = 48000;

typedef struct
{
    AudioStreamBasicDescription  dataFormat;
    AudioQueueRef                queue;
    AudioQueueBufferRef          buffers[kNumberBuffers];
    AudioFileID                  audioFile;
    SInt64                       currentPacket;
    bool                         playing;
    bool                         paused;
} PlayState;

static int AIRPlayerPacketReadCallback(OGGZ *oggz, ogg_packet *packet, long serialno, void *user_data)
{
    AIROpusAudioPlayer *player = (__bridge AIROpusAudioPlayer*)user_data;
    
    NSData *data = [NSData dataWithBytes:packet->packet length:packet->bytes];
    
    [player.opusDecoder decode:data];
    
    return OGGZ_CONTINUE;
}

static int pageCallback(OGGZ *oggz, const ogg_page *og, long serialno, void *user_data)
{
    return OGGZ_CONTINUE;
}

void AudioOutputCallback(void * inUserData,
                         AudioQueueRef outAQ,
                         AudioQueueBufferRef outBuffer);

@interface AIROpusAudioPlayer ()

@property (nonatomic, assign) PlayState playState;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) CSIOpusDecoder *opusDecoder;


@end

@implementation AIROpusAudioPlayer

void AudioOutputCallback(void * inUserData,
                         AudioQueueRef outAQ,
                         AudioQueueBufferRef outBuffer)
{
    
    AIROpusAudioPlayer *player = (__bridge AIROpusAudioPlayer*)inUserData;
	PlayState playState = player.playState;
    
    if(!playState.playing || playState.paused)
    {
        printf("Not playing, returning\n");
        return;
    }
    
    int bytes = [player.opusDecoder fillQueue:playState.queue outBuffer:outBuffer];
    
    if(bytes == 0)
    {
        AudioQueueStop(playState.queue, false);
        
        if(playState.playing == true)
        {
            [player sendStateChangeBlock:AIROpusAudioPlayerStateChangeEnd];
        }
        
        playState.playing = false;
        player.playState = playState;
        
        NSError *deactivationError = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryAmbient error:nil];
        BOOL success = [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        if (!success) {
            NSLog(@"%@", [deactivationError localizedDescription]);
        }
    }
}

- (id)initWithFileURL:(NSURL*)url
{
    self = [super init];
    
    if(self)
    {
        self.opusDecoder = [[CSIOpusDecoder alloc] initWithSampleRate:kSampleRate
                                                             channels:1
                                                        frameDuration:kFrameDuration];
        self.fileURL = url;
    }
    
    return self;
}

- (void)dealloc
{
    self.stateChangeBlock = nil;
    [self stop];
}

- (void)startPlayback
{
    float bufferDuration = kFrameDuration;
    int bytesPerSample = sizeof(AudioSampleType);
    int samplesPerFrame = (int)(bufferDuration * kSampleRate);
    int bytesPerFrame = samplesPerFrame * bytesPerSample;
    
    if([self readFileIntoBuffer:YES])
    {
        BOOL success = NO;
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        success = [session setCategory:AVAudioSessionCategoryPlayback error:&error];
        if (!success) {
            NSLog(@"%@ Error setting category: %@",
                  NSStringFromSelector(_cmd), [error localizedDescription]);
        }
        
        success = [session setActive:YES error:&error];
        if (!success) {
            NSLog(@"%@", [error localizedDescription]);
        }

        [NSThread sleepForTimeInterval:.01];
        
        OSStatus status = noErr;
        
        status = [self createAudioQueue];
        
        if (status == 0)
        {
            _playState.playing = true;
            for (int i = 0; i < kNumberBuffers && _playState.playing; i++)
            {
                AudioQueueAllocateBuffer(_playState.queue, bytesPerFrame, &_playState.buffers[i]);
                AudioOutputCallback((__bridge void*)self, _playState.queue, _playState.buffers[i]);
            }
            
            status = AudioQueueStart(_playState.queue, NULL);
            if (status == 0)
            {
                [self sendStateChangeBlock:AIROpusAudioPlayerStateChangePlaying];
            }
            else
            {
                [self sendStateChangeBlock:AIROpusAudioPlayerStateChangeError];
            }
        }
        else
        {
            [self stop];
            [self sendStateChangeBlock:AIROpusAudioPlayerStateChangeError];
        }
    }
}

- (OSStatus)createAudioQueue
{
    AudioQueueStop(_playState.queue, true);
    [self setupAudioFormat:&_playState.dataFormat sampleRate:kSampleRate];
    
    OSStatus status = noErr;
    
    status = AudioQueueNewOutput(&_playState.dataFormat,
                                 AudioOutputCallback,
                                 (__bridge void*)self,
                                 nil,
                                 nil,
                                 0,
                                 &_playState.queue);
    
    return status;
}

- (BOOL)readFileIntoBuffer:(BOOL)async
{
    float bufferDuration = kFrameDuration;
    int bytesPerSample = sizeof(AudioSampleType);
    int samplesPerFrame = (int)(bufferDuration * kSampleRate);
    int bytesPerFrame = samplesPerFrame * bytesPerSample;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.fileURL.path])
    {
        [self sendStateChangeBlock:AIROpusAudioPlayerStateChangeError];
        return NO;
    }
    
    const char *path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:self.fileURL.path];
    
    dispatch_queue_t dispatchQueue = async ?
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) : dispatch_get_main_queue();
    
    dispatch_async(dispatchQueue, ^{
        
        OGGZ *oggzReader = oggz_open(path, OGGZ_READ|OGGZ_AUTO);
        
        long serial = -1;
        
        oggz_seek (oggzReader, 0, SEEK_SET);
        oggz_set_read_page(oggzReader, serial, pageCallback, (__bridge void*)self);
        oggz_set_read_callback(oggzReader, serial, AIRPlayerPacketReadCallback, (__bridge void*)self);
        
        int n;
        while ((n = oggz_read (oggzReader, bytesPerFrame)) > 0);
        
        free(oggzReader);
    });
    
    return YES;
}

- (void)stop
{
    _playState.playing = false;
    _playState.paused = NO;
    AudioQueueStop(_playState.queue, true);
    AudioQueueDispose(_playState.queue, true);
    [self sendStateChangeBlock:AIROpusAudioPlayerStateChangeStopped];
    
    NSError *deactivationError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryAmbient error:nil];
    BOOL success = [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    if (!success) {
        NSLog(@"%@", [deactivationError localizedDescription]);
    }

}

- (void)pause
{
    if(self.playState.playing && _playState.paused == NO)
    {
        _playState.paused = YES;
        //AudioQueuePause(_playState.queue);
        AudioQueueStop(_playState.queue, false);
        [self sendStateChangeBlock:AIROpusAudioPlayerStateChangePaused];
    }
}

- (void)resume
{
    if(_playState.paused == YES)
    {
        _playState.paused = NO;

        AudioQueueEnqueueBuffer(_playState.queue, _playState.buffers[0], 0, NULL);
        AudioQueueEnqueueBuffer(_playState.queue, _playState.buffers[1], 0, NULL);
        AudioQueueEnqueueBuffer(_playState.queue, _playState.buffers[2], 0, NULL);
        AudioQueuePrime(_playState.queue, 3, NULL);
        
        OSStatus status = AudioQueueStart(_playState.queue, NULL);
        
        if(status == noErr)
        {
            [self sendStateChangeBlock:AIROpusAudioPlayerStateChangeResumed];
        }
        else
        {
            [self sendStateChangeBlock:AIROpusAudioPlayerStateChangeError];
        }
    }
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

- (BOOL)isPlaying
{
    return _playState.playing ? YES : NO;
}

- (BOOL)isPaused
{
    return _playState.paused ? YES : NO;
}

- (void)sendStateChangeBlock:(AIROpusAudioPlayerStateChange)stateChange
{
    if(self.stateChangeBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stateChangeBlock(self, stateChange);
        });
    }
}
@end
