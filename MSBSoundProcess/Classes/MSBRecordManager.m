//
//  MSBRecordManager.m
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/11/2.
//

#import "MSBRecordManager.h"
#import "MSBAudioMacro.h"
#import <PFAudioLib/PFAudio.h>
#import "MSBAudioConvertor.h"
#import "MSBUnityAudioCaptureInterface.h"
#import "MSBAudioMIDITool.h"

@interface MSBRecordManager()

@property(nonatomic, strong)    NSFileHandle *audioFileHandle1;
@property (nonatomic, copy)     NSString *audioFilePath1;

//@property(nonatomic, strong)    NSFileHandle *audioFileHandle2;
//@property (nonatomic, copy)     NSString *audioFilePath2;
//
//@property(nonatomic, strong)    NSFileHandle *audioFileHandle3;
//@property (nonatomic, copy)     NSString *audioFilePath3;
@property (nonatomic, copy)     NSString *currentAudioPath;

@property (nonatomic,assign)    BOOL canAudioCapture;                  // 是否可以音频采集的开关
@property (nonatomic,assign)    BOOL isStartRecorder;
@property (nonatomic,assign)    BOOL isPause;                           // 暂停录制

@end
@implementation MSBRecordManager
- (instancetype)init {
    if (self = [super init]) {
        [self initSetupRecordFile];
    }
    return self;
}
- (void)recordOutputAudioData:(NSData *)outputdata {
    if (outputdata && outputdata.length > 0) {
        // 音频录制
        if (self.isStartRecorder && !self.isPause) {
            [self.audioFileHandle1 writeData:outputdata];
        }
    }
}
- (void)startRecord {
    if (_isStartRecorder == NO) {
        self.isStartRecorder = YES;
        [self initSetupRecordFile];
    }else {
        return;
    }
    MSBAudioLog(@"开始录制音频");
}
- (void)stopRecord {
    MSBAudioLog(@"停止录制音频");
    if (self.isStartRecorder) {
        self.isStartRecorder = NO;
        MSBUnityAudioCaptureInterface.shared.isStartedRecord = NO;
        [self coveredPCMtoWavFile:self.audioFilePath1];

        [self.audioFileHandle1 closeFile];
//        [self.audioFileHandle2 closeFile];
//        [self.audioFileHandle3 closeFile];
    }
    self.isPause = NO;
}
- (void)pauseRecord {
    self.isPause = YES;
}
- (void)resumeRecord {
    self.isPause = NO;
}
- (void) coveredPCMtoWavFile:(NSString*)pcmPath {
    PFAudio *pfaudio = [PFAudio shareInstance];
    pfaudio.attrs =@{AVSampleRateKey: @(kMSBAudioSampleRate),
                     AVNumberOfChannelsKey: @(kMSBAudioChannelNumber)};
    
    BOOL res = [pfaudio pcm2Wav:pcmPath  isDeleteSourchFile:NO];
    if (res) {
        MSBAudioLog(@"转换wav成功 %@",pcmPath);
        NSString *outPath = [[pcmPath stringByDeletingPathExtension] stringByAppendingString:@".wav"];
        [self coveredWAVtoMP3File: outPath];
    }else {
        MSBAudioLog(@"转换wav失败 %@",self.audioFilePath1);
    }
}

- (void)coveredWAVtoMP3File:(NSString*)wavPath {
    MSBAudioLog(@"转换mp3");
    typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [MSBAudioConvertor convertPCMToMp3:wavPath success:^(NSString * _Nonnull mp3Path) {
            MSBAudioLog(@"转换mp3成功 %@",mp3Path);
            weakSelf.currentAudioPath = mp3Path;
            if (mp3Path) {
                // 录制视频和 转换mp3完成之后的回调方法
                // C方法调用改为OC 代理方法
                [weakSelf.delegate recordAudioFileFinish:mp3Path];
            }
        } failure:^(NSError * _Nonnull error) {

        }];
    });
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
    
//    // 处理后pcm数据
//    NSString *filePath2 = [NSString stringWithFormat:@"%@_%@",videoDestDateString,kAudioRecordConvertedPCMFile];
//    self.audioFilePath2 = [fileName stringByAppendingPathComponent:filePath2];
//    if ([NSFileManager.defaultManager fileExistsAtPath:self.audioFilePath2]) {
//        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath2 error:nil];
//    }
//    [[NSFileManager defaultManager] createFileAtPath:self.audioFilePath2 contents:nil attributes:nil];
//    self.audioFileHandle2 = [NSFileHandle fileHandleForWritingAtPath:self.audioFilePath2];
//
//    // 处理后wav数据
//    NSString *filePath3 = [NSString stringWithFormat:@"%@_%@",videoDestDateString,kAudioRecordConvertedWAVFile];
//    self.audioFilePath3 = [fileName stringByAppendingPathComponent:filePath3];
//    if ([NSFileManager.defaultManager fileExistsAtPath:self.audioFilePath3]) {
//        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath3 error:nil];
//    }
//    [[NSFileManager defaultManager] createFileAtPath:self.audioFilePath3 contents:nil attributes:nil];
//    self.audioFileHandle3 = [NSFileHandle fileHandleForWritingAtPath:self.audioFilePath3];
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
- (NSString*)getCurrentWavVoiceFilePath {
    if (!_currentAudioPath) {
        //        MSBAudioLog(@"wav文件路径为nil");
        MSBAudioLog(@"mp3文件路径为nil");
        return nil;
    }
    return _currentAudioPath;
}
@end
