//
//  MSBAudioKitInterface.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/6/29.
//

#import <Foundation/Foundation.h>
#import <SoundProcess/SoundProcess.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSBAudioKitInterface <NSObject>
- (void)processedAudioWithPitch:(MSBVoiceAnalysisInfo *)analysisInfo;
- (void)processedAudioData:(MSBVoiceAnalysisPitchAndNoteInfo *)analysisInfo;
- (void)processedAudioIsHaveVoice:(BOOL)isHaveVad;
- (void)processedAudioMatchResult:(int)result analysisInfo:(MSBVoiceAnalysisPitchAndNoteInfo *)analysisInfo;;
- (void)processeStarted;
- (void)backgroundMusicPlayEnd;
- (void)processResumeReadyed;
- (void)playerTime:(float)time position:(float)position;

- (void)recordAudioFileFinish:(NSString *)mp3Path;
- (void)tensorflowCallback:(int)resultid;

@end

NS_ASSUME_NONNULL_END
