//*******************************************************************************
// Educational Online Test Delivery System
// Copyright (c) 2015 American Institutes for Research
//
// Distributed under the AIR Open Source License, Version 1.0
// See accompanying file AIR-License-1_0.txt or at
// http://www.smarterapp.org/documents/American_Institutes_for_Research_Open_Source_Software_License.pdf
//*******************************************************************************
//
//  AIRJSCommand.h
//  Secure Browser
//
//  Created by Kenny Roethel on 5/10/13.
//

#import <Foundation/Foundation.h>

/* Commands that can be issued by the web page */
extern NSString *const kCheckGuidedAccessRequest;
extern NSString *const kCheckTTSRequest;
extern NSString *const kCheckNativeProcessesRequest;
extern NSString *const kCMD_Initialize;
extern NSString *const kJavascriptLog;
extern NSString *const kSetDefaultURL;
extern NSString *const kLockOrientation;
extern NSString *const kSpeakText;
extern NSString *const kPauseSpeech;
extern NSString *const kResumeSpeech;
extern NSString *const kStopSpeakingText;
extern NSString *const kInitializeAudioRecorder;
extern NSString *const kEndAudioCapture;
extern NSString *const kStartAudioCapture;
extern NSString *const kStartAudioPlayback;
extern NSString *const kStopAudioPlayback;
extern NSString *const kPauseAudioPlayback;
extern NSString *const kResumeAudioPlaback;
extern NSString *const kRequestAudioFileList;
extern NSString *const kRequestAudioFile;
extern NSString *const kClearAudioCache;

extern NSString *const kClearWebCache;
extern NSString *const kClearWebCookies;

extern NSString *const kEnableGuidedAccess;

extern NSString *const kTTSSetPitch;
extern NSString *const kTTSSetRate;
extern NSString *const kTTSSetVolume;

@class AIROpusAudioRecorder;
@class AIRTTSEngine;

/**
 *  Convenience class to handle AIR Mobile Secure Browser Javascript commands.
 *  The provided methods handle their respective JS commands and return a javascript
 *  string to execute in the browser as a response.
 */
@interface AIRJSCommand : NSObject

+ (NSString*)handleAudioFileRequest:(NSString*)params;
+ (NSString*)handleClearAudioFileCache:(NSString*)params;
+ (NSString*)handleRequestAudioFiles:(NSString*)params;
+ (NSString*)handleRequestProcessList:(NSString*)params;
+ (NSString*)handleTextToSpeechCheck:(NSString*)params ttsEngine:(AIRTTSEngine*)ttsEngine;
+ (NSString*)handleAudioProgress:(NSNumber*)bytes duration:(NSNumber*)duration;
+ (NSString*)handleSendAudioFile:(NSString*)filename quality:(NSString*)quality trackLength:(NSTimeInterval)trackLength;
+ (NSString*)handleGuidedAccessCheck:(NSString*)params;
+ (NSString*)handleSetDefaultURL:(NSString*)params;
+ (NSString*)handleInitializeRecorder:(NSString*)params recorder:(AIROpusAudioRecorder*)recorder;
+ (NSString*)handleUnsupportedRequest:(NSString*)params;
+ (NSString*)handleBeginRecording:(NSString*)params recorder:(AIROpusAudioRecorder*)recorder;

+ (NSDictionary*)getRecordingCapabilities:(BOOL)available;
+ (NSString*)getIP;

@end
