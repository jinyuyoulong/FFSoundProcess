//
//  MSBAudioTensorflowManager.m
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/7/3.
//

#import "MSBAudioTensorflowManager.h"
#import <msbaudioai/msbaudioai.h>
#import <PFAudioLib/PFAudio.h>
#import "MSBAudioConvertor.h"
#import "MSBAudioMacro.h"
#import "MSBUnityAudioCaptureInterface.h"
#import "MSBAudioCaptureManager.h"

@interface MSBAudioTensorflowManager()
@property (nonatomic, strong) MSBAudioAi* audioai;
@end

@implementation MSBAudioTensorflowManager
+(MSBAudioTensorflowManager*)shared {
    static MSBAudioTensorflowManager *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[MSBAudioTensorflowManager alloc] init];
    });
    return _shared;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initFeiZhouGuData];
    }
    return self;
}
- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void)feizhouguPlay{
    [_audioai msbplay];
    
}

- (void)feizhouguPause {
    [_audioai msbpause];
}
- (void)initFeiZhouGuData {
    _audioai = [MSBAudioAi alloc];
    __block  __weak typeof(self) wself = self;
    _audioai.block = ^(int resultid) {
        [wself.delegate tensorflowCallback:resultid];
    };
    
    
    NSString *tflitefilepath = [[NSBundle mainBundle] pathForResource:@"drumbeat_model" ofType:@"tflite"];
    
    MSBAudioLog(@"%@",tflitefilepath);
    
    NSString *recordfilepath = [[self applicationDocumentsDirectory] stringByAppendingString:@"/record.wav"];
    MSBAudioLog(@"%@",recordfilepath);
    
    NSString *logfilepath = [[self applicationDocumentsDirectory] stringByAppendingString:@"/log.txt"];
    MSBAudioLog(@"%@",logfilepath);
    
    [_audioai msbinitaudioai:tflitefilepath andRecordPath:recordfilepath andLogPath:logfilepath];
}

- (void)coveredPCMtoWavFile:(NSString*)pcmPath {
    NSString *wavPath = [[pcmPath stringByDeletingPathExtension] stringByAppendingString:@".wav"];
    PFAudio *pfaudio = [PFAudio shareInstance];
    pfaudio.attrs =@{AVSampleRateKey: @(kMSBAudioSampleRate),AVNumberOfChannelsKey: @(kMSBAudioChannelNumber)};
    // pcm -> wav
    BOOL res = [pfaudio pcm2Wav:pcmPath isDeleteSourchFile:NO];
    if (res) {
        MSBAudioLog(@"转换wav成功");
        // wav -> mp3
        [self coveredWAVtoMP3File:wavPath];
    }else {
        MSBAudioLog(@"转换wav失败");
    }
}

- (void)coveredWAVtoMP3File:(NSString *)wavFile {
    MSBAudioLog(@"转换mp3");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [MSBAudioConvertor convertPCMToMp3:wavFile success:^(NSString * _Nonnull mp3Path) {
            if (mp3Path) {
                // 录制视频和 转换mp3完成之后的回调方法
                [MSBAudioCaptureManager.share.delegate recordAudioFileFinish:mp3Path];
            }
        } failure:^(NSError * _Nonnull error) {

        }];
    });
}

@end
