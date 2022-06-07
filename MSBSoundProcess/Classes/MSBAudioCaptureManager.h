//
//  MSBAudioCaptureManager.h
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/2/14.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SoundProcess/SoundProcess.h>
#import "MSBAudioKitInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSBAudioCaptureManager : NSObject
@property (nonatomic, weak, nullable)id<MSBAudioKitInterface> delegate;

+ (MSBAudioCaptureManager *)share;

/// 开始采集
- (void) startAudioCapture;
- (void) stopAudioCapture;

/// 开始声音处理
- (void) startVoiceProcess;
- (void) stopVoiceProcess;

/// 开始录音
- (void) startRecordAudioCapture;
- (void) stopRecordAudioCapture;

- (MSBVoicePitchInfo*) getCurrentPitch;
- (MSBVoiceVadInfo*) getCurrentVad;
- (MSBVoiceNoteInfo*) getCurrentNote;
- (NSString*) getCurrentWavVoiceFilePath;
- (void)captureOutputAudioData:(NSData *)audioData;
- (void)captureProcessPitch:(NSData *)audioData;
- (nonnull NSData *)preProcessAns:(nonnull NSData *)inData
                      inSampleCnt:(int32_t)inSampleCnt;
#pragma mark - Initializer
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;
@end

NS_ASSUME_NONNULL_END
