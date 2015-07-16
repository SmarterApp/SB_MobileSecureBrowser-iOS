//
//  AIRTTSEngine.m
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

#import "AIRTTSEngine.h"
#import "GTMNSString+HTML.h"
#import "AVFoundation/AVFoundation.h"
#import "NSJSONSerialization+AIR.h"

static NSString *const kPlayingTTSStatus = @"playing";
static NSString *const kPausedTTSStatus = @"paused";
static NSString *const kIdleTTSStatus = @"idle";

@interface AIRTTSEngine () <AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate>

@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, assign) BOOL isNativeVoicePackUsed;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSMutableArray *availableLanguagePacks;
@property (nonatomic, strong) NSMutableArray *additionalTTSProperties;
@property (nonatomic, strong) NSDictionary *ttsSettings;
@property (nonatomic, assign) int currentPitch;
@property (nonatomic, assign) int currentRate;
@property (nonatomic, assign) int currentVolume;

@end

@implementation AIRTTSEngine

- (id)init
{
    self = [super init];

    if(self)
    {
        self.availableLanguagePacks = [NSMutableArray array];
        NSString *nsResourcePath = [[NSBundle mainBundle] resourcePath];
        self.isNativeVoicePackUsed = false;
        
        NSString *osVer = [[UIDevice currentDevice] systemVersion];
        
        if ([osVer characterAtIndex:0] != '6') {
            // set the default pitch, rate, and volume as current
            self.currentPitch = 1.0;
            self.currentRate = 0.1;
            self.currentVolume = 1.0;
            
            // retrieve voice pack available on the iOS device for iOS 7 and later OS
            self.additionalTTSProperties = [[NSMutableArray alloc] initWithCapacity:2];
            for (int i=0; i<2; i++) {
                [self.additionalTTSProperties addObject:[NSNull null]];
            }
            NSArray* speechVoices = [AVSpeechSynthesisVoice speechVoices];
            if(speechVoices) {
                for (int i=0; i<speechVoices.count; i++) {
                    AVSpeechSynthesisVoice *speechVoice = [speechVoices objectAtIndex:i];
                    NSString *language = speechVoice.language;
                    if (language) {
                        [self.availableLanguagePacks addObject:@{@"language" : language, @"voice" : language}];
                        if ([language isEqualToString:@"es-ES"]) {
                            // store the Spanish voice pack
                            [self.additionalTTSProperties replaceObjectAtIndex:0 withObject:speechVoice];
                        }
                    }
                }
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
}

-(NSDictionary*)ttsSettings
{
    NSString *pitchStr = [NSString stringWithFormat:@"%d",self.currentPitch];
    NSString *rateStr = [NSString stringWithFormat:@"%d",self.currentRate];
    NSString *volumeStr = [NSString stringWithFormat:@"%d",self.currentVolume];
    
    NSDictionary *currentSettings = @{@"pitch" : pitchStr,
                                      @"rate" : rateStr,
                                      @"volume" : volumeStr};
    return currentSettings;
}

-(BOOL)ttsSetPitch:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSString *pitch = [((NSDictionary*)object) objectForKey:@"pitch"];
        if (pitch)
        {
            self.currentPitch = pitch.integerValue >= 0 ? pitch.integerValue: self.currentPitch;
            return YES;
        }
    }
    return NO;
}

-(BOOL)ttsSetRate:(NSString *)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSString *rate = [((NSDictionary*)object) objectForKey:@"rate"];
        if (rate)
        {
            self.currentRate = rate.integerValue >= 0 ? rate.integerValue : self.currentRate;
            return YES;
        }
    }
    return NO;
}

-(BOOL)ttsSetVolume:(NSString *)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSString *volume = [((NSDictionary*)object) objectForKey:@"volume"];
        if (volume)
        {
            self.currentVolume = volume.integerValue >= 0 ? volume.integerValue : self.currentVolume;
            return YES;
        }
    }
    return NO;
}

-(void)speakText:(NSString *)text
{
    [self speakText:text options:nil];
}

-(void)speakText:(NSString *)text options:(NSDictionary*)options
{
    NSString *language = options[@"language"];
    
    NSNumber *prefferedSpeed = [self numberFromDictionary:options key:@"rate"];
    NSNumber *prefferedVolume = [self numberFromDictionary:options key:@"volume"];
    NSNumber *prefferedPitch = [self numberFromDictionary:options key:@"pitch"];
    
    int speed = prefferedSpeed.integerValue ? : self.currentRate;
    int volume = prefferedVolume.integerValue ? : self.currentVolume;
    int pitch = prefferedPitch.integerValue ? : self.currentPitch;
    
    NSString *cleanString = text;
    
    // do not speak empty text
    if (cleanString.length == 0) {
        return;
    }
	
    if ([text canBeConvertedToEncoding:NSUnicodeStringEncoding])
    {
        NSData * data = [text dataUsingEncoding:NSUnicodeStringEncoding];
        cleanString = [[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding];
    }
    
    cleanString = [cleanString gtm_stringByUnescapingFromHTML];

	
    NSString *tempFilePath = [self tempFilePath];
    
    NSString *osVer = [[UIDevice currentDevice] systemVersion];
    
    self.isNativeVoicePackUsed = YES;
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance
                                    speechUtteranceWithString:cleanString];
    
    if ([language isEqualToString:@"es-ES"]) {
        if ([self.additionalTTSProperties objectAtIndex:0]) {
            utterance.voice = [self.additionalTTSProperties objectAtIndex:0];
        }
    }
    
    // convert settings to the values that are accepted for the Neospeech engine
    utterance.rate = (float)speed / 50;
    utterance.pitchMultiplier = (float)pitch / 20 * 1.5 + 0.5;
    utterance.volume = (float)volume / 20;
    
    if ([self.additionalTTSProperties objectAtIndex:1]) {
        [self.additionalTTSProperties replaceObjectAtIndex:1 withObject:[[AVSpeechSynthesizer alloc] init]];
    }
    
    AVSpeechSynthesizer *synth = [self.additionalTTSProperties objectAtIndex:1];
    if (synth) {
        self.isPlaying = YES;
        self.isPaused = NO;
        synth.delegate = self;
        [synth speakUtterance:utterance];
    }
}

- (NSNumber*)numberFromDictionary:(NSDictionary*)dict key:(NSString*)key
{
    id value = dict[key];
    
    if([value isKindOfClass:[NSString class]])
    {
        return @(((NSString*)value).integerValue);
    }
    else if([value isKindOfClass:[NSNumber class]])
    {
        return (NSNumber*)value;
    }
    else
    {
        return nil;
    }
}

- (NSString*)defaultLanguage
{
    return self.availableLanguagePacks[0];
}

- (void)logValue:(NSString*)value withMessage:(NSString*)message
{
    //Do nothing - subclasses may handle if they choose to log
}

- (void)playbackAudio:(NSString*)filePath
{
    NSError *err;
    [self.audioPlayer stop];
	
    self.audioPlayer =  [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:&err];
	[self.audioPlayer setDelegate:self];
   
    self.isPlaying = YES;
    self.isPaused = NO;
	[self.audioPlayer play];
}

- (NSString*)tempFilePath
{
    NSArray *filePaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *recordingDirectory = [filePaths objectAtIndex: 0];
    NSString *tempFilePath = [NSString stringWithFormat: @"%@/%s", recordingDirectory, "temp.wav"];
    
    return tempFilePath;
}

-(void)stopSpeech
{
    if (!self.isNativeVoicePackUsed) {
        self.isPlaying = NO;
        self.isPaused = NO;
        [self.audioPlayer stop];
    }
    else {
        // call the native IOS API to stop TTS playback
        AVSpeechSynthesizer *synth = [self.additionalTTSProperties objectAtIndex:1];
        if (synth) {
            BOOL result = [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            if (result) {
                self.isPlaying = NO;
                self.isPaused = NO;
            }
        }
    }
}

- (void)pauseSpeech
{
    if (!self.isNativeVoicePackUsed) {
        [self.audioPlayer pause];
        self.isPaused = YES;
    }
    else {
        // call the native IOS API to pause TTS playback
        AVSpeechSynthesizer *synth = [self.additionalTTSProperties objectAtIndex:1];
        if (synth) {
            BOOL result = [synth pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            if (result) {
                self.isPaused = YES;
            }
        }
    }
}

- (void)resumeSpeech
{
    if(self.isPaused)
    {
        if (!self.isNativeVoicePackUsed) {
            self.isPaused = NO;
        
            [self.audioPlayer play];
            NSTimeInterval position = self.audioPlayer.currentTime;
            position = position - .5f >= 0 ? position - .5f : 0;
            [self.audioPlayer pause];
            [self.audioPlayer setCurrentTime:position];
        
            [self.audioPlayer play];
        }
        else {
            // call the native IOS API to resume TTS playback
            AVSpeechSynthesizer *synth = [self.additionalTTSProperties objectAtIndex:1];
            if (synth) {
                BOOL result = [synth continueSpeaking];
                if (result) {
                    self.isPaused = NO;
                }
            }

        }
    }
}

- (NSString*)statusString
{
    if(self.isPlaying)
    {
        return self.isPaused ? @"paused" : @"playing";
    }
    
    return @"idle";
}

#pragma mark - AVAudioPlayer Delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.isPlaying = NO;
    self.isPaused = NO;
    
    if([self.delegate respondsToSelector:@selector(airTTSDidFinishPlaying:successfully:)])
    {
        [self.delegate airTTSDidFinishPlaying:self successfully:flag];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    self.isPlaying = NO;
    self.isPaused = NO;
    
    if([self.delegate respondsToSelector:@selector(airTTSDecodeErrorDidOccur:error:)])
    {
        [self.delegate airTTSDecodeErrorDidOccur:self error:error];
    }
}

#pragma mark - AVSpeechSynthesizer Delegate

// TTS voice tracking
-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance {
    // tts playback synchronization (tracking progress)
    NSString *currentWord = [utterance.speechString substringWithRange:characterRange];
    NSUInteger currentLocation = characterRange.location;
    NSUInteger currentLength = characterRange.length;
    NSLog(@"about to say %@ at position %d with length %d", currentWord, currentLocation, currentLength);
    [self.delegate airTTSSynchronize:self word:currentWord location:currentLocation length:currentLength];
    
}

// called when TTS playback is finished
-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.isPlaying = NO;
    self.isPaused = NO;
    
    if([self.delegate respondsToSelector:@selector(airTTSDidFinishPlaying:successfully:)])
    {
        [self.delegate airTTSDidFinishPlaying:self successfully:TRUE];
    }
}

@end
