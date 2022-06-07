//
//  MSBAudioCaptureManager.m
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/2/14.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import "MSBAudioCaptureManager.h"
#import "MSBAudioCapture.h"
#import <PFAudioLib/PFAudio.h>
#import "MSBAudioConvertor.h"
#import "MSBAudioMacro.h"
#import "MSBUnityAudioCaptureInterface.h"
#import "MSBAudioMIDITool.h"

@interface MSBAudioCaptureManager ()<MSBAudioCaptureDelegate>
{
    NSTimer *timer;
    int timer_margin;
    
    BOOL istimerloop;
}
@property (nonatomic,strong)    MSBVoicePreprocess *voicePreProcess;
@property (nonatomic,strong)    MSBVoiceAnalysisProcess *voiceAnalysisProcess;
@property (nonatomic, strong)   MSBVoiceAnalysisInfo *analysisInfo;

/// 音频采集
@property (nonatomic, strong)   MSBAudioCapture *audioCaptureSource;

@property(nonatomic, strong)    NSFileHandle *audioFileHandle1;
@property (nonatomic, copy)     NSString *audioFilePath1;

@property(nonatomic, strong)    NSFileHandle *audioFileHandle2;
@property (nonatomic, copy)     NSString *audioFilePath2;

@property(nonatomic, strong)    NSFileHandle *audioFileHandle3;
@property (nonatomic, copy)     NSString *audioFilePath3;
@property (nonatomic, copy)     NSString *currentAudioPath;

@property (nonatomic,assign)    BOOL canAudioCapture;                  // 是否可以音频采集的开关
@property (nonatomic,assign)    BOOL isStartRecorder;
@property (nonatomic,assign)    BOOL isVoiceProcess;
@property (nonatomic,assign)    NSUInteger  currentRunCount;

@end


@implementation MSBAudioCaptureManager

- (void)dealloc
{
    MSBAudioLog(@"%s",__func__);
}
+ (MSBAudioCaptureManager *)share {
    static MSBAudioCaptureManager * _shareObj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_shareObj) {
            _shareObj = [[MSBAudioCaptureManager alloc] init];
        }
    });
    
    return  _shareObj;
}
- (MSBAudioCapture *)audioCaptureSource {
    if (!_audioCaptureSource) {
        _audioCaptureSource = [[MSBAudioCapture alloc] init];
        _audioCaptureSource.delegate = self;
    }
    return _audioCaptureSource;
}

- (MSBVoicePreprocess *)voicePreProcess {
    if (!_voicePreProcess) {
        _voicePreProcess = [MSBVoicePreprocess createVoicePreprocess];
        [_voicePreProcess init:kMSBAudioSampleRate channel:kMSBAudioChannelNumber];
    }
    return _voicePreProcess;
}

- (MSBVoiceAnalysisProcess *)voiceAnalysisProcess {
    if (!_voiceAnalysisProcess) {
        _voiceAnalysisProcess = [MSBVoiceAnalysisProcess createVoiceAnalysisProcess];
        [_voiceAnalysisProcess init:kMSBAudioSampleRate channel:kMSBAudioChannelNumber];
    }
    return _voiceAnalysisProcess;
}
// 新版本处理pitch
- (void)captureProcessPitch:(NSData *)audioData {
    if (self.isVoiceProcess) {

        dispatch_async(dispatch_get_main_queue(), ^{
            //vod;返回1有声音返回0没声音;
            int ret = [self.voicePreProcess preProcessVod:audioData inSampleCnt:(int32_t)audioData.length / 2];
            if (ret == 1) {
                //检测结构体;
                MSBVoiceAnalysisPitchAndNoteInfo * m_analysisInfoPitchAndNoteInfo = [self.voiceAnalysisProcess getPitchAndNote:audioData inSampleCnt:audioData.length / 2];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(processedAudioData:)]) {
                    [self.delegate processedAudioData: m_analysisInfoPitchAndNoteInfo];
                }
            }else {
                MSBAudioLog(@"没有人声");
                if (self.delegate && [self.delegate respondsToSelector:@selector(processedAudioDataVoice:)]) {
                    [self.delegate processedAudioIsHaveVoice:false];
                }
            }
        });
    }
}
// 老版本处理音频入口
- (void)captureOutputAudioData:(NSData *)outputdata {
//    self.currentRunCount++;
//    if (self.currentRunCount == NSUIntegerMax) {
//        self.currentRunCount = 0;
//    }
    //****** agc + ans ******//
//        NSData *outputdata = [self.voicePreProcess preProcess:inputdata inSampleCnt:inputdata.length / 2];
//
//        // agc
//        //agc;
//        NSData *outputdata = [self.voicePreProcess preProcessAgc:inputdata inSampleCnt:inputdata.length / 2];
//
//        //****** ans ******//
//        //ans;
//        NSData *outputdata = [self.voicePreProcess preProcessAns:inputdata inSampleCnt:inputdata.length / 2];
    
    if (outputdata && outputdata.length > 0) {
        // 音频录制
        if (self.isStartRecorder) {
            [self.audioFileHandle2 writeData:outputdata];
        }
        
        if (self.currentRunCount % 5 != 0) { // 每10帧才执行一次 降噪和音高检测等接口，降低CPU的使用
            // 小狐狸，哼唱游戏，测试 %5 合适。
            return;
        }
//
        if (self.isVoiceProcess) {
// 必须在该线程处理
            dispatch_async(dispatch_get_main_queue(), ^{
                _analysisInfo = [self.voiceAnalysisProcess getVoiceAnalysisInfoRealtime:outputdata
                                                                            inSampleCnt:(int32_t)outputdata.length / 2];
            });
            if (self.delegate && [self.delegate respondsToSelector:@selector(processedAudioWithPitch:)]) {
                if (!_analysisInfo) {
                    return;
                }
                [self.delegate processedAudioWithPitch:_analysisInfo];
            }
            
        }
    }
    
}
// MARK: - delegate
/// 麦克风数据回调
/// @param capture 采集者
/// @param audioData 音频数据
- (void)captureOutput:(MSBAudioCapture *)capture audioData:(NSData *)audioData
{
    if (!self.canAudioCapture) {
        return;
    }
    
//    MSBAudioLog(@"audioData.length: %ld",audioData.length);
    
    if (!audioData) {
        MSBAudioLog(@"音频数据为空++++++++++++++++++++++++++++++");
        return;
    }
    
    @synchronized (self) {
        NSData *outputdata = [self.voicePreProcess preProcessAns:audioData
                                                     inSampleCnt:(int32_t)audioData.length / 2];
        if (outputdata && outputdata.length > 0) {
            // 音频录制
            if (self.isStartRecorder) {
                [self.audioFileHandle2 writeData:outputdata];
            }

            [self captureProcessPitch:outputdata];
        }
    }
}
- (nonnull NSData *)preProcessAns:(nonnull NSData *)inData
                      inSampleCnt:(int32_t)inSampleCnt {
    return [self.voicePreProcess preProcessAns:inData
                                   inSampleCnt:(int32_t)inData.length / 2];
}
- (MSBVoicePitchInfo*) getCurrentPitch {
    if (!_analysisInfo || _analysisInfo.pitchSeq.count == 0) {
        return nil;
    }
    return _analysisInfo.pitchSeq.lastObject;
}

- (MSBVoiceVadInfo*) getCurrentVad {
    if (!_analysisInfo || _analysisInfo.vadResult.count == 0) {
        return nil;
    }
    return _analysisInfo.vadResult.lastObject;
}

- (MSBVoiceNoteInfo*) getCurrentNote {
    if (!_analysisInfo || _analysisInfo.noteSeq.count == 0) {
        return nil;
    }
    return _analysisInfo.noteSeq.lastObject;
}

- (void) coveredPCMtoWavFile {
    PFAudio *pfaudio = [PFAudio shareInstance];
    pfaudio.attrs =@{AVSampleRateKey: @(kMSBAudioSampleRate),AVNumberOfChannelsKey: @(kMSBAudioChannelNumber)};
    
    BOOL res = [pfaudio pcm2Wav:self.audioFilePath2 isDeleteSourchFile:NO];
    if (res) {
        MSBAudioLog(@"转换wav成功");
        [self coveredWAVtoMP3File];
    }else {
        MSBAudioLog(@"转换wav失败");
    }
}

- (void)coveredWAVtoMP3File {
    MSBAudioLog(@"转换mp3");
    typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [MSBAudioConvertor convertPCMToMp3:weakSelf.audioFilePath3 success:^(NSString * _Nonnull mp3Path) {
            weakSelf.currentAudioPath = mp3Path;
            if (mp3Path) {
//                recordAudioFileFinish([mp3Path UTF8String]);     // 录制视频和 转换mp3完成之后的回调方法
                // C方法调用改为OC 代理方法
                [weakSelf.delegate recordAudioFileFinish:mp3Path];
            }
        } failure:^(NSError * _Nonnull error) {

        }];
    });
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)initSetupRecordFile {
    NSString *videoDestDateString = [self createFileNamePrefix];

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString * filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = [filePath stringByAppendingPathComponent:kAudioFileName];
    if (![fm fileExistsAtPath:fileName])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:fileName
                                                         withIntermediateDirectories:YES
                                                                          attributes:nil
                                                                               error:nil];
    }
    
    // 处理前pcm数据
    NSString *filePath1 = [NSString stringWithFormat:@"%@_%@",videoDestDateString,kAudioRecordPCMFile];
    self.audioFilePath1 = [fileName stringByAppendingPathComponent:filePath1];
    if ([NSFileManager.defaultManager fileExistsAtPath:self.audioFilePath1]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath1 error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:self.audioFilePath1 contents:nil attributes:nil];
    self.audioFileHandle1 = [NSFileHandle fileHandleForWritingAtPath:self.audioFilePath1];
    
    // 处理后pcm数据
    NSString *filePath2 = [NSString stringWithFormat:@"%@_%@",videoDestDateString,kAudioRecordConvertedPCMFile];
    self.audioFilePath2 = [fileName stringByAppendingPathComponent:filePath2];
    if ([NSFileManager.defaultManager fileExistsAtPath:self.audioFilePath2]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath2 error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:self.audioFilePath2 contents:nil attributes:nil];
    self.audioFileHandle2 = [NSFileHandle fileHandleForWritingAtPath:self.audioFilePath2];
    
    // 处理后wav数据
    NSString *filePath3 = [NSString stringWithFormat:@"%@_%@",videoDestDateString,kAudioRecordConvertedWAVFile];
    self.audioFilePath3 = [fileName stringByAppendingPathComponent:filePath3];
    if ([NSFileManager.defaultManager fileExistsAtPath:self.audioFilePath3]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath3 error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:self.audioFilePath3 contents:nil attributes:nil];
    self.audioFileHandle3 = [NSFileHandle fileHandleForWritingAtPath:self.audioFilePath3];
}

/**
 *  创建文件名
 */
- (NSString *)createFileNamePrefix
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmssSSS"];//zzz
    NSString *destDateString = [dateFormatter stringFromDate:[NSDate date]];
    return destDateString;
}

- (void)startAudioCapture {
    MSBAudioLog(@"开始采集音频");
    self.canAudioCapture = YES;
    
    if (!self.audioCaptureSource.isRunning) {
        self.isVoiceProcess = YES;
        [self.audioCaptureSource startAudio];
        
    } else {
        MSBAudioLog(@"麦克风状态不正确");
    }
}

- (void)stopAudioCapture {
    MSBAudioLog(@"结束采集音频");
    self.canAudioCapture = NO;
    if (self.audioCaptureSource.isRunning) {
        [self.audioCaptureSource stopAudio];
        
        if (self.isStartRecorder) {
            [self stopRecordAudioCapture];
        }
        if (self.isVoiceProcess) {
            self.isVoiceProcess = NO;
        }
    } else {
        [self.audioCaptureSource stopAudio];
    }
}

- (void)startVoiceProcess {
    self.isVoiceProcess = YES;
}

- (void)stopVoiceProcess {
    self.isVoiceProcess = NO;
    // 重置音频处理
    self.voiceAnalysisProcess = nil;
    self.voicePreProcess = nil;
    self.analysisInfo = nil;
}

- (void)startRecordAudioCapture {
    MSBAudioLog(@"开始录制音频");
    [self initSetupRecordFile];
    if (self.audioCaptureSource.isRunning) {
        self.isStartRecorder = YES;
        MSBUnityAudioCaptureInterface.shared.isStartedRecord = YES;
    } else {
        [self startAudioCapture];
        self.isStartRecorder = YES;
        MSBUnityAudioCaptureInterface.shared.isStartedRecord = YES;
    }
}

- (void)stopRecordAudioCapture {
    MSBAudioLog(@"停止录制音频");
    if (self.isStartRecorder) {
        self.isStartRecorder = NO;
        MSBUnityAudioCaptureInterface.shared.isStartedRecord = NO;
        [self coveredPCMtoWavFile];

        [self.audioFileHandle1 closeFile];
        [self.audioFileHandle2 closeFile];
        [self.audioFileHandle3 closeFile];
    }
}

- (NSString*)getCurrentWavVoiceFilePath {
    if (!_currentAudioPath) {
        //        MSBAudioLog(@"wav文件路径为nil");
        MSBAudioLog(@"mp3文件路径为nil");
        return nil;
    }
    return _currentAudioPath;
}



@end
