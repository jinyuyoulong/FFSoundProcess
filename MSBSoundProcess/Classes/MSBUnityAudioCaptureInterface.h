//
//  MSBUnityAudioCaptureInterface.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/15.
//

#import <Foundation/Foundation.h>
#import "MSBAudioKitInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSBUnityAudioCaptureInterface : NSObject
@property (nonatomic, assign)BOOL islog;
@property (nonatomic, weak, nullable)id<MSBAudioKitInterface> delegate;
@property (nonatomic, assign)BOOL isStartedMic;
@property (nonatomic, assign)BOOL isStartedRecord;
@property (nonatomic, assign)BOOL isHaveBgmusic;

+ (MSBUnityAudioCaptureInterface*)shared;

// 背景音预处理
- (void)preProcessBgAudioFile:(NSString*)path;
/// 开始音频采集
/// @param type  0 =
- (void)startAudioCapture:(int)type;
- (void)stopAudioCapture:(int)type;
- (void)startCaptureWithBgMusic:(NSString *)path;

//- (void)readyResumeAudioprocess;
- (void)resumeAudioProcess;
- (void)pauseAudioProcess;

- (void)startVoiceProcess;
- (void)stopVoiceProcess;
- (NSString*)voicePitchProcess;
- (NSString*)voiceVadProcess;
- (NSString*)voiceNoteProcess;

/// 开始播放
/// @param type 1 去噪音 2 其他
- (void)openAudioCapture:(int)type sampleRate:(int)sampleRate channel:(int)channel;
/// 获取音频捕获的数据
/// @param msg byte 转为 string 传递
- (NSData *)updateAudioCaptureData:(NSString*)msg;

- (void)getMatchNote:(NSString *)noteName level:(int)level
             isMatch:(bool)ismatch matchType:(int)matchType
           minOctave:(int)minOctave maxOctave:(int) maxOctave;
- (void)getAudioFilterPrecentage:(float)filterPercentage;

//MARK: - 开始录制
- (void)startRecordVoice;
- (NSString*)stopRecordVoice;
- (void)pauseAudioRecord;
- (void)resumeAudioRecord;
@end

NS_ASSUME_NONNULL_END
