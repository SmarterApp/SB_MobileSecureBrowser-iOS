//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRJSCommand.m
//  Secure Browser
//
//  Created by Kenny Roethel on 5/10/13.
//

#import "AIRJSCommand.h"
#import "AIROpusAudioRecorder.h"
#import "AIROpusAudioPlayer.h"
#import "NSData+Base64MG.h"
#import "NSJSONSerialization+AIR.h"
#import "AIRProcesses.h"
#import "AIRTTSEngine.h"
#import "NSString+UUID.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

NSString *const kCheckGuidedAccessRequest    = @"cmdCheckGuidedAccess";
NSString *const kCheckTTSRequest             = @"cmdCheckTTS";
NSString *const kCheckNativeProcessesRequest = @"cmdGetNativeProcesses";
NSString *const kCMD_Initialize              = @"cmdInitialize";
NSString *const kJavascriptLog               = @"cmdJavascriptLog";
NSString *const kSetDefaultURL               = @"cmdSetDefaultURL";
NSString *const kLockOrientation             = @"cmdLockOrientation";
NSString *const kSpeakText                   = @"cmdSpeakText";
NSString *const kPauseSpeech                 = @"cmdPauseSpeaking";
NSString *const kResumeSpeech                = @"cmdResumeSpeaking";
NSString *const kStopSpeakingText            = @"cmdStopSpeaking";
NSString *const kInitializeAudioRecorder     = @"cmdInitializeRecorder";
NSString *const kEndAudioCapture             = @"cmdEndAudioCapture";
NSString *const kStartAudioCapture           = @"cmdStartAudioCapture";
NSString *const kStartAudioPlayback          = @"cmdPlaybackAudio";
NSString *const kStopAudioPlayback           = @"cmdStopAudioPlayback";
NSString *const kPauseAudioPlayback          = @"cmdPauseAudioPlayback";
NSString *const kResumeAudioPlaback          = @"cmdResumeAudioPlayback";
NSString *const kRequestAudioFileList        = @"cmdRequestAudioFileList";
NSString *const kRequestAudioFile            = @"cmdRequestAudioFile";
NSString *const kClearAudioCache             = @"cmdRequestClearAudioCache";

NSString *const kClearWebCache               = @"cmdRequestClearWebCache";
NSString *const kClearWebCookies             = @"cmdRequestClearCookies";
NSString *const kGetMACAddress               = @"cmdRequestGetMACAddress";
NSString *const kGetStartTime                = @"cmdRequestGetStartTime";

NSString *const kEnableGuidedAccess          = @"cmdEnableGuidedAccess";
NSString *const kTTSSetPitch                 = @"cmdSetPitch";
NSString *const kTTSSetRate                  = @"cmdSetRate";
NSString *const kTTSSetVolume                = @"cmdSetVolume";

NSString *const kCheckMicAccessStatus        = @"cmdCheckMicAccessStatus";


//Json and Dictionary Keys
static NSString *const kIdentifierKey = @"identifier";
static NSString *const kFilenameKey = @"filename";
static NSString *const kBase64Key = @"base64";
static NSString *const kAudioInfoKey = @"audioInfo";
static NSString *const kFilesKey = @"files";
static NSString *const kRecordingsKey = @"recordings";
static NSString *const kRecordingNameKey = @"recordingName";

// event names
static NSString *const kGuidedAccessChangedEvent = @"event_guided_access_changed";

//Multiple to convert a kilobyte value into bytes
static const float kKilobyteConversionFactor = 0.000976562;

@implementation AIRJSCommand

+ (NSString*)handleAudioFileRequest:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    NSDictionary *parameters = nil;
    NSString *filename = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
        filename = [((NSDictionary*)object) objectForKey:kFilenameKey];
    }
    
    NSString *path = [AIROpusAudioRecorder fileStoragePath];
    NSURL *url = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:filename]];
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:url.path];
    
    NSString *base64 = [data base64EncodedString];
    
    NSDictionary *dataDict = @{kBase64Key : base64 ? base64 : [NSNull null],
                               kFilenameKey : filename ? filename : [NSNull null]};
    
    if(identifier)
    {
        parameters = @{kAudioInfoKey : dataDict ? dataDict : [NSNull null], kIdentifierKey : identifier};
    }
    else
    {
        parameters = @{kAudioInfoKey : dataDict ? dataDict : [NSNull null]};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"AIRMobile.ntvOnAudioFileDataRetrieved('%@')", jsonString];
}

+ (NSString*)handleRetrieveAudioFile:(NSDictionary*)params
{
    NSString *identifier = nil;
    NSDictionary *parameters = nil;
    NSString *filename = nil;
    
    identifier = [params objectForKey:kIdentifierKey];
    filename = [params objectForKey:kFilenameKey];
    
    NSString *path = [AIROpusAudioRecorder fileStoragePath];
    NSURL *url = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:filename]];
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:url.path];
    
    NSString *base64 = [data base64EncodedString];
    
    NSDictionary *dataDict = @{kBase64Key : base64 ? base64 : [NSNull null],
                               kRecordingNameKey : filename ? filename : [NSNull null]};
    
    if(identifier)
    {
        parameters = @{kAudioInfoKey : dataDict ? dataDict : [NSNull null], kIdentifierKey : identifier};
    }
    else
    {
        parameters = @{kAudioInfoKey : dataDict ? dataDict : [NSNull null]};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"SecureBrowser.recorder.onRetrieveAudioFile('%@')", jsonString];
}

+ (NSString*)handleClearAudioFileCache:(NSString*)params
{
    NSError *error = nil;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[AIROpusAudioRecorder fileStoragePath] error:&error];
    if (error == nil)
    {
        for (NSString *path in directoryContents)
        {
            NSString *fullPath = [[AIROpusAudioRecorder fileStoragePath] stringByAppendingPathComponent:path];
            BOOL removeSuccess = [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                
                NSLog(@"error %@", error);
            }
        }
    } else
    {
        NSLog(@"Error no content: %@ %@", error, [AIROpusAudioRecorder fileStoragePath]);
    }
    
    return [self handleRequestAudioFiles:params];
}

+ (NSString*)handleRemoveAudioFiles:(NSString*)identifier
{
    NSError *error = nil;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[AIROpusAudioRecorder fileStoragePath] error:&error];
    if (error == nil)
    {
        for (NSString *path in directoryContents)
        {
            NSString *fullPath = [[AIROpusAudioRecorder fileStoragePath] stringByAppendingPathComponent:path];
            BOOL removeSuccess = [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                
                NSLog(@"error %@", error);
            }
        }
    } else
    {
        NSLog(@"Error no content: %@ %@", error, [AIROpusAudioRecorder fileStoragePath]);
    }
    
    if (identifier)
    {
        return [self handleRetrieveAudioFiles:identifier];
    }
}

+ (NSString*)handleRequestAudioFiles:(NSString*)params
{
    NSString *path = [AIROpusAudioRecorder fileStoragePath];
    NSError *error = nil;
    
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    NSDictionary *parameters = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
    }
    
    if(identifier)
    {
        parameters = @{kFilesKey : directoryContents ? directoryContents : [NSNull null], kIdentifierKey : identifier};
    }
    else
    {
        parameters = @{kFilesKey : directoryContents ? directoryContents : [NSNull null]};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"AIRMobile.ntvOnAudioFileListRetrieved('%@')", jsonString];
}

+ (NSString*)handleRetrieveAudioFiles:(NSString*)identifier
{
    NSString *path = [AIROpusAudioRecorder fileStoragePath];
    NSError *error = nil;
    
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    NSDictionary *parameters = nil;
    
    if(identifier)
    {
        parameters = @{kRecordingsKey : directoryContents ? directoryContents : [NSNull null], kIdentifierKey : identifier};
    }
    else
    {
        parameters = @{kRecordingsKey : directoryContents ? directoryContents : [NSNull null]};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"SecureBrowser.recorder.onRetrieveAudioFiles('%@')", jsonString];
}


+ (NSString*)handleRequestProcessList:(NSString*)params
{
    NSArray *process = [AIRProcesses currentProcesses];
    NSDictionary *JSONParams = nil;
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
    }
    
    if(identifier)
    {
        JSONParams = @{@"runningProcesses" : process, kIdentifierKey : identifier};
    }
    else
    {
        JSONParams = @{@"runningProcesses" : process};
    }
    
    
    return [NSString stringWithFormat:@"AIRMobile.ntvOnRunningProcessesUpdated('%@')", [NSJSONSerialization JSONStringFromDictionary:JSONParams error:nil]];
}

+ (NSString*)handleExamineProcessList:(NSString*)identifier blacklist:(NSArray*)blacklist
{
    NSArray *process = [AIRProcesses currentProcesses];
    NSDictionary *JSONParams = nil;
    
    // find the intersection between running processes and blacklisted processes
    NSMutableSet *runningProcessesSet = [NSMutableSet setWithArray: process];
    NSSet *blacklistedProcessesSet = [NSSet setWithArray: blacklist];
    [runningProcessesSet intersectSet: blacklistedProcessesSet];
    NSArray *detectedProcesses = [runningProcessesSet allObjects];
    
    if(identifier)
    {
        JSONParams = @{@"blacklist" : detectedProcesses, kIdentifierKey : identifier};
    }
    else
    {
        JSONParams = @{@"blacklist" : detectedProcesses};
    }
    
    return [NSString stringWithFormat:@"SecureBrowser.security.onExamineProcessList('%@')", [NSJSONSerialization JSONStringFromDictionary:JSONParams error:nil]];
}

+ (NSString*)handleTextToSpeechCheck:(NSString*)params ttsEngine:(AIRTTSEngine*)ttsEngine
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    NSDictionary *parameters = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
    }
    
    if(identifier)
    {
        parameters = @{@"enabled" : @(UIAccessibilityIsVoiceOverRunning()), @"ttsEngineStatus" : [ttsEngine statusString], kIdentifierKey : identifier};
    }
    else
    {
        parameters = @{@"enabled" : @(UIAccessibilityIsVoiceOverRunning()), @"ttsEngineStatus" : [ttsEngine statusString]};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"AIRMobile.ntvOnTextToSpeechEnabled('%@')", jsonString];
}

+ (NSString*)handleTextToSpeechStatusCheck:(NSString*)identifier ttsEngine:(AIRTTSEngine*)ttsEngine ttsCommand:(NSString*)ttsCommand
{
    NSDictionary *parameters = nil;
    
    // report the correct state
    NSString *state = [ttsEngine statusString];
    if (ttsCommand != (id)[NSNull null] && ttsCommand.length > 0 ) {
        if ([ttsCommand isEqualToString:@"pause"]) {
            if ([state isEqualToString:@"Paused"]) {
                state = @"pause";
            } else {
                state = @"error";
            }
        } else if ([ttsCommand isEqualToString:@"resume"]) {
            if ([state isEqualToString:@"Playing"]) {
                state = @"resume";
            } else {
                state = @"error";
            }
        } else if ([ttsCommand isEqualToString:@"stop"]) {
            if ([state isEqualToString:@"Stopped"]) {
                state = @"stop";
            } else {
                state = @"error";
            }
        }
    }
    
    if(identifier)
    {
        parameters = @{@"enabled" : @(UIAccessibilityIsVoiceOverRunning()), @"state" : state, @"identifier" : identifier};
    }
    else
    {
        parameters = @{@"enabled" : @(UIAccessibilityIsVoiceOverRunning()), @"state" : state};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"SecureBrowser.tts.onTTSStatus('%@')", jsonString];
}

+ (NSString*)handleAudioProgress:(NSNumber*)bytes duration:(NSNumber*)duration
{
    NSDictionary *parameters = @{@"type": @"INPROGRESS",
                                 @"kilobytesRecorded" : @(bytes.integerValue * kKilobyteConversionFactor),
                                 @"secondsRecorded" : duration};
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    return [NSString stringWithFormat:@"SecureBrowser.recorder.onRecorderStatus('%@')", jsonString];
}

+ (NSString*)handleSendAudioFile:(NSString*)filename quality:(NSString*)quality trackLength:(NSTimeInterval)trackLength
{
    NSURL *url = [NSURL fileURLWithPath:[AIROpusAudioRecorder fileStoragePath]];
    url = [url URLByAppendingPathComponent:filename];
    
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:url.path];
    
    NSString *base64 = [data base64EncodedString];
    
    NSDictionary *dataDict = @{kBase64Key : base64 ? base64 : [NSNull null],
                               kRecordingNameKey : filename ? filename : [NSNull null],
                               @"qualityIndicator" : quality ? quality : @"unknown"};
    
    NSDictionary *content = @{@"type" : @"END",
                              @"kilobytesRecorded" : @(data.length * kKilobyteConversionFactor),
                              @"secondsRecorded" : @(trackLength),
                              @"error" : data.length > 0 ? [NSNull null] : @"Error saving file",
                              @"data" : dataDict};
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:content options:0 error:nil];
    NSString *cont = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return [NSString stringWithFormat:@"SecureBrowser.recorder.onRecorderStatus('%@')", cont];
}

+ (NSString*)handleGuidedAccessCheck:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    NSDictionary *parameters = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
    }
    
    if(identifier)
    {
        parameters = @{@"enabled" : @(UIAccessibilityIsGuidedAccessEnabled()), kIdentifierKey : identifier};
    }
    else
    {
        parameters = @{@"enabled" : @(UIAccessibilityIsGuidedAccessEnabled())};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"AIRMobile.ntvOnGuidedAccessEnabled('%@')", jsonString];
}

+ (NSString*)updateGuidedAccessStatus
{
    NSDictionary *parameters = nil;
    
    parameters = @{@"event": kGuidedAccessChangedEvent, @"enabled" : @(UIAccessibilityIsGuidedAccessEnabled())};
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"SecureBrowser.events.onEventDispatched('%@')", jsonString];
}

+ (NSString*)handleSetDefaultURL:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    NSString *url = nil;
    NSDictionary *parameters = nil;
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
        url = [((NSDictionary*)object) objectForKey:@"url"];
    }
    
    if(url)
    {
        [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"default_region_selection"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if(identifier)
    {
        parameters = @{@"url" : url ? url : [NSNull null], kIdentifierKey : identifier};
    }
    else
    {
        parameters = @{@"url" : url ? url : [NSNull null]};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"AIRMobile.ntvOnSetDefaultURL('%@')", jsonString];
}

+ (NSString*)handleUnsupportedRequest:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSString *identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
        
        NSDictionary *parameters = nil;
        
        if(identifier)
        {
            parameters = @{kIdentifierKey : identifier};
            
            NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
            
            return [NSString stringWithFormat:@"AIRMobile.ntvOnRequestNotSupported('%@')", jsonString];
        }
    }
    
    return nil;
}

+ (NSString*)handleCheckMicAccessStatus:(NSString*)params
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    NSString *identifier = nil;
    NSDictionary *parameters = nil;
    NSString *status = @"undetermined";
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        identifier = [((NSDictionary*)object) objectForKey:kIdentifierKey];
    }

    NSString *osVer = [[UIDevice currentDevice] systemVersion];
    
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)])
    {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            // NSLog(@"permission : %d", granted);
            NSDictionary *parameters = nil;
            if(identifier)
            {
                if (granted)
                {
                    parameters = @{@"status" : @"granted", kIdentifierKey : identifier};
                }
                else
                {
                    parameters = @{@"status" : @"denied", kIdentifierKey : identifier};
                }
            }
            else
            {
                if (granted)
                {
                    parameters = @{@"status" : @"granted"};
                }
                else
                {
                    parameters = @{@"status" : @"denied"};
                }
            }
            NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
            
            // return [NSString stringWithFormat:@"AIRMobile.ntvOnMicAccessStatus('%@')", jsonString];
        }];
    }
    else
    {
        if(identifier)
        {
            parameters = @{@"status" : status, kIdentifierKey : identifier};
        }
        else
        {
            parameters = @{@"status" : status};
        }
    }

    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"AIRMobile.ntvOnMicAccessStatus('%@')", jsonString];

}

+ (NSString*)handleInitializeRecorder:(NSString*)identifier recorder:(AIROpusAudioRecorder*)recorder
{
    NSDictionary *parameters = nil;
    
    NSDictionary *capabilities = [self getRecordingCapabilities:recorder ? YES : NO];
    
    NSString *state = recorder ? @"READY" : @"ERROR";
    
    if(identifier)
    {
        parameters = @{@"state" : state, @"capabilities" : capabilities, kIdentifierKey : identifier};
    }
    else
    {
        parameters = @{@"state" : state, @"capabilities" : capabilities};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"SecureBrowser.recorder.onInitialized('%@')", jsonString];
}

+ (NSString*)handleBeginRecording:(NSString*)params recorder:(AIROpusAudioRecorder*)recorder
{
    NSObject *object = [NSJSONSerialization JSONObject:params];
    
    int sampleRate = 48000;
    int deviceID = 0;
    int channelCount = 1;
    int sampleSize = 16;
    NSString *encodingFormat = @"opus";
    int updateInterval = -1;
    int duration = -1, size = -1;
    AIROpusCallbackType callbackType = AIROpusCallbackTypeNone;
    NSString *filename = [NSString stringWithFormat:@"%@.opus", [NSString UUID]];
    
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *params = (NSDictionary*)object;
        
        if([params objectForKey:@"sampleRate"]) sampleRate = [[params objectForKey:@"sampleRate"] integerValue];
        if([params objectForKey:@"captureDevice"]) deviceID = [[params objectForKey:@"captureDevice"] integerValue];
        if([params objectForKey:@"channelCount"]) channelCount = [[params objectForKey:@"channelCount"] integerValue];
        if([params objectForKey:@"sampleSize"]) sampleSize = [[params objectForKey:@"sampleSize"] integerValue];
        if([params objectForKey:@"encodingFormat"]) encodingFormat = [params objectForKey:@"encodingFormat"];
        if([params objectForKey:kFilenameKey]) filename = [params objectForKey:kFilenameKey];
        
        callbackType = [self progressUpdateType:params];
        updateInterval = [self progressInterval:params];
        duration = [self durationLimit:params];
        size = [self sizeLimit:params];
    }
    
    [recorder setRecordingLimit:duration bytes:size];
    [recorder setCallbackFrequency:updateInterval forType:callbackType];
    [recorder startRecording:filename sampleRate:sampleRate];
    
    NSNumber *progress = [[NSNumber alloc]initWithInteger:0];
    NSNumber *dur = [[NSNumber alloc]initWithInteger:0];
    return [self handleAudioProgress:progress duration:dur];
}

+ (NSString*)handleGetRecorderStatus:(NSString*)identifier recorder:(AIROpusAudioRecorder*)recorder player:(AIROpusAudioPlayer*)player;
{
    NSString* status = @"";
    NSDictionary* parameters;
    
    if (recorder)
    {
        if ([recorder isRecording]) {
            status = @"ACTIVE";
        } else if (player) {
            if ([player isPaused]) {
                status = @"PAUSED";
            } else if ([player isPlaying]) {
                status = @"PLAYING";
            } else {
                status = @"IDLE";
            }
        } else {
            status = @"IDLE";
        }
    }
    
    if (identifier)
    {
        parameters = @{@"status" : status, @"identifier" : identifier };
    }
    else
    {
        parameters = @{@"status" : status};
    }
    
    NSString *jsonString = [NSJSONSerialization JSONStringFromDictionary:parameters error:nil];
    
    return [NSString stringWithFormat:@"SecureBrowser.recorder.onGetRecorderStatus('%@')", jsonString];
}
                                                                 
+ (int)durationLimit:(NSDictionary*)params
{
    NSObject *obj = [params objectForKey:@"captureLimit"];
    int interval = -1;
    
    if([obj isKindOfClass:[NSDictionary class]])
    {
        id intervalValue = [(NSDictionary*)obj objectForKey:@"duration"];
        if([intervalValue respondsToSelector:@selector(integerValue)])
            interval = [intervalValue integerValue];
    }
    
    return interval;
}

+ (int)sizeLimit:(NSDictionary*)params
{
    NSObject *obj = [params objectForKey:@"captureLimit"];
    int size = -1;
    
    if([obj isKindOfClass:[NSDictionary class]])
    {
        id sizeValue = [(NSDictionary*)obj objectForKey:@"size"];
        if([sizeValue respondsToSelector:@selector(integerValue)])
            size = [sizeValue integerValue];
    }
    
    return size * 1024;
}

+ (int)progressInterval:(NSDictionary*)params
{
    NSObject *obj = [params objectForKey:@"progressFrequency"];
    
    int interval = -1;
    
    if([obj isKindOfClass:[NSDictionary class]])
    {
        id intervalValue = [(NSDictionary*)obj objectForKey:@"interval"];
        if([intervalValue respondsToSelector:@selector(integerValue)])
            interval = [intervalValue integerValue];
    }
    
    AIROpusCallbackType callbackType = [self progressUpdateType:params];
    
    return callbackType == AIROpusCallbackTypeSize ? interval * 1024 : interval;
}

+ (AIROpusCallbackType)progressUpdateType:(NSDictionary*)params
{
    NSObject *obj = [params objectForKey:@"progressFrequency"];
    
    AIROpusCallbackType  type = AIROpusCallbackTypeNone;
    
    if([obj isKindOfClass:[NSDictionary class]])
    {
        id typeValue = [(NSDictionary*)obj objectForKey:@"type"];
        if([typeValue isKindOfClass:[NSString class]])
        {
            if([((NSString*)typeValue).lowercaseString isEqualToString:@"size"])
                type = AIROpusCallbackTypeSize;
            
            if([((NSString*)typeValue).lowercaseString isEqualToString:@"time"])
                type = AIROpusCallbackTypeTime;
        }
    }
    
    return type;
}

+ (NSDictionary*)getRecordingCapabilities:(BOOL)available
{
    NSArray *sampleRates = @[@(48000), @(24000), @(16000), @(12000), @(8000)];
    
    NSArray *inputDevices = @[@{@"id": @(0),
                           @"description" : @"Microphone",
                           @"sampleSizes" : @[@(16)],
                           @"sampleRates" : sampleRates,
                           @"channels" : @[@(1)],
                           @"encodingFormats" : @[@"opus"],
                           @"default": @YES
                           }];
    NSArray *outputDevices = @[@{@"id": @(0),
                                @"description" : @"Speaker",
                                @"sampleSizes" : @[@(16)],
                                @"sampleRates" : sampleRates,
                                @"channels" : @[@(1)],
                                @"encodingFormats" : @[@"opus"],
                                @"default": @YES
                                }];
    
    return  @{@"isAvailable" : @(available),
              @"supportedInputDevices" : inputDevices,
              @"supportedOutputDevices" : outputDevices};
}

+(NSString*)getIP {
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] rangeOfString:@"en"].location != NSNotFound) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

@end
