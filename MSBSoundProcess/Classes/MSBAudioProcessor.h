//
//  MSBAudioProcessor.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/10/13.
//

#import <Foundation/Foundation.h>
#import "MSBRecordManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSBAudioProcessor : NSObject

@property (nonatomic, strong)NSString *matchNote;
@property (nonatomic, assign)int matchLevel;
@property (nonatomic, assign)int minOctave;
@property (nonatomic, assign)int maxOctave;
@property (nonatomic, assign)BOOL isMatch;
@property (nonatomic, assign)int matchType;
@property (nonatomic, assign)float filterPercentage;
@property (nonatomic, assign)BOOL isHaveBgmusic;
@property (nonatomic, assign)BOOL isProcessingData;
@property (nonatomic, strong)NSString *bgMusicPath;
@property (nonatomic, strong)MSBRecordManager *recorder;

- (void)startPlayAndRecordProcessWithPath:(NSString*)path;
- (void)stopPlayAndRecordProcessWithPath;
- (void)onlyStartRecordAndProcessAudioData;
- (void)onlyStopRecordAndProcessAudioData;


//- (void)startCapture;
//- (void)stopCapture;
//

//
- (void)preProcessBgAudioFile:(NSString*)path;

//- (void)readyResumeAudioprocess;

/// 开始处理
- (void)startProcess;

/// 结束处理
- (void)stopProcess;

/// 继续处理
- (void)resumeAudioProcess;

/// 暂停处理
- (void)pauseAudioProcess;


/// 录音
- (void)startRecord;
- (void)stopRecord;
- (void)pauseAudioRecord;
- (void)resumeAudioRecord;

- (NSString*)getCurrentWavVoiceFilePath;
@end

NS_ASSUME_NONNULL_END
