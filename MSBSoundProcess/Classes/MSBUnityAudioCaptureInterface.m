//
//  MSBUnityAudioCaptureInterface.m
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/15.
//

#import "MSBUnityAudioCaptureInterface.h"
#import "MSBAudioCaptureManager.h"
#import "MSBAudioCompositioner.h"
#import <AVFoundation/AVFoundation.h>
#import "MSBAudioMacro.h"
#import "MSBAudioManager.h"
#import "MSBAudioTensorflowManager.h"
#import "MSBAudioProcessor.h"

//#import <OSAbility/OSAbility-umbrella.h>
@import OSAbility;
@interface MSBUnityAudioCaptureInterface()
{
    BOOL _isProcessing;
}
@property (nonatomic, strong)MSBAudioProcessor *audioProcessor;
@property (nonatomic, strong)NSString *bgMusicPath;
@end

@implementation MSBUnityAudioCaptureInterface
+ (MSBUnityAudioCaptureInterface*)shared {
    static MSBUnityAudioCaptureInterface *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[MSBUnityAudioCaptureInterface alloc] init];
    });
    return _shared;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initNotification];
        [OSAudioSessionManager shared];
    }
    return self;
}

- (MSBAudioProcessor *)audioProcessor {
    if (!_audioProcessor) {
        _audioProcessor = [MSBAudioProcessor new];
    }
    return  _audioProcessor;
}
- (void)setDelegate:(id<MSBAudioKitInterface>)delegate {
    _delegate = delegate;
    self.audioProcessor.recorder.delegate = delegate;
}
- (void)startAudioCapture:(int)type {
    if (self.isStartedMic == true) {
        return;
    }
    if (type == 0) {
        [OSAudioSessionManager.shared saveLastestAudioSession];
//        [[MSBAudioCaptureManager share] startAudioCapture];
//        _isHaveBgmusic = false;
//        [self.audioProcessor onlyStartRecordAndProcessAudioData];
    } else if(type ==1) {
        [MSBAudioTensorflowManager.shared feizhouguPlay];
    }
    self.isStartedMic = true;
}
- (void)stopAudioCapture:(int)type {
    if (self.isStartedMic == false) {
        return;
    }
    
    if (type == 0) {
//        [OSAudioSessionManager.shared resetOriginAudioSession];
//        [[MSBAudioCaptureManager share] stopAudioCapture];
        
        if (_isHaveBgmusic) {
            [self.audioProcessor stopPlayAndRecordProcessWithPath];
        } else {
            [self.audioProcessor onlyStopRecordAndProcessAudioData];
        }
        self.audioProcessor.isHaveBgmusic = false;
        _isHaveBgmusic = false;
//        dispatch_sync(dispatch_get_main_queue(), ^{
            
//        });
        
    } else if(type ==1) {
        [MSBAudioTensorflowManager.shared feizhouguPause];
    }
    self.isStartedMic = false;
}
- (void)startCaptureWithBgMusic:(NSString *)path {
    [self stopVoiceProcess];
    [self stopAudioCapture:0];
    
    self.bgMusicPath = path;
    _isHaveBgmusic = true;
    self.audioProcessor.isHaveBgmusic = true;
    
    [self startAudioCapture:0];
    [self startVoiceProcess];
//    [self.audioProcessor preProcessBgAudioFile:path];
//    [self startVoiceProcess];
}

//- (void)readyResumeAudioprocess {
//    [self.audioProcessor readyResumeAudioprocess];
//}
- (void)resumeAudioProcess {
    [self.audioProcessor resumeAudioProcess];
}
- (void)pauseAudioProcess {
    [self.audioProcessor pauseAudioProcess];
}

- (void)startVoiceProcess {
    [self.audioProcessor startProcess];
    if (!self.isStartedMic) {
        
        if (_isHaveBgmusic) {
            [self.audioProcessor startPlayAndRecordProcessWithPath:self.bgMusicPath];
        } else {
            [self.audioProcessor onlyStartRecordAndProcessAudioData];
        }
        _isProcessing = true;
    } else {
        if (_isHaveBgmusic) {
            [self.audioProcessor startPlayAndRecordProcessWithPath:self.bgMusicPath];
        }else {
            [self.audioProcessor onlyStartRecordAndProcessAudioData];
        }
        _isProcessing = true;
    }
//    [[MSBAudioCaptureManager share] startVoiceProcess];
}
- (void)stopVoiceProcess {
//    [[MSBAudioCaptureManager share] stopVoiceProcess];
    _isProcessing = false;
    [self.audioProcessor stopProcess];
//    if (self.isStartedMic) {
//        if (_isHaveBgmusic) {
//            [self.audioProcessor stopPlayAndRecordProcessWithPath];
//        } else {
//            [self.audioProcessor onlyStopRecordAndProcessAudioData];
//        }
//    }
}
/// 开始播放
/// @param type 1 去噪音 2 其他
- (void)openAudioCapture:(int)type sampleRate:(int)sampleRate channel:(int)channel {
    MSBAudioLog(@"%d",type);
//    获取麦克风权限
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                             completionHandler:^(BOOL granted) {
        if (granted) {
        }
        else {
            MSBAudioLog(@"没有权限");
        }
    }];
}
/// 获取音频捕获的数据
/// @param msg byte 转为 string 传递
- (NSData *)updateAudioCaptureData:(NSString*)msg {
    MSBAudioLog(@"inputData:%s",msg);
    NSData *outputdata;
        
    // base64解码
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:msg options:0];
        
    // 音频转换
    MSBAudioLog(@"inputData:%@",decodedData);
    
    // data 转 string
//    NSString *plainString = [[NSString alloc] initWithData:outputdata encoding:NSUTF8StringEncoding];
//    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    
    // base64编码
    NSData *base64OutputData = [outputdata base64EncodedDataWithOptions:0];
    return  base64OutputData;
//    char *a = (char *)[base64OutputData bytes];
//    return a;
}

- (void)getMatchNote:(NSString *)noteName level:(int)level
             isMatch:(bool)ismatch matchType:(int)matchType
           minOctave:(int)minOctave maxOctave:(int) maxOctave {
    self.audioProcessor.matchNote = noteName;
    self.audioProcessor.matchLevel = level;
    self.audioProcessor.isMatch = ismatch;
    self.audioProcessor.matchType = matchType;
    self.audioProcessor.minOctave = minOctave;
    self.audioProcessor.maxOctave = maxOctave;
}
- (void)getAudioFilterPrecentage:(float)filterPercentage {
    self.audioProcessor.filterPercentage = filterPercentage;
}
- (void)preProcessBgAudioFile:(NSString*)path {
    self.bgMusicPath = path;
    _isHaveBgmusic = true;
    self.audioProcessor.isHaveBgmusic = true;
    [self.audioProcessor preProcessBgAudioFile:path];
}

// MARK: - 录音
static NSTimeInterval startRecordTime = 0;
static NSTimeInterval endRecordTime = 0;
- (void)startRecordVoice {
//    [[MSBAudioCaptureManager share] startRecordAudioCapture];
//    startRecordTime = NSDate.now.timeIntervalSince1970;
//    NSLog(@"%s %lf",__func__,startRecordTime);
    self.isStartedRecord = true;
    [self.audioProcessor startRecord];
}
- (NSString*)stopRecordVoice {
//    endRecordTime = NSDate.now.timeIntervalSince1970;
//    NSTimeInterval durition = endRecordTime - startRecordTime;
//    NSLog(@"%s %lf",__func__,endRecordTime);
//    NSLog(@"%s %lf %lf %lf",__func__,endRecordTime, startRecordTime, durition);
//    [[MSBAudioCaptureManager share] stopRecordAudioCapture];
    self.isStartedRecord = false;
    [self.audioProcessor stopRecord];
    NSString *path = [self.audioProcessor getCurrentWavVoiceFilePath];
//    NSString *path = [[MSBAudioCaptureManager share] getCurrentWavVoiceFilePath];
    if (path) {
        //字符串拷贝库函数，一般和free()函数成对出
//        return strdup([path UTF8String]);
    } else {
        path = @"";
    }
//    MSBAudioLog(@"音频路径：%@",path);
    return path;
}
- (void)pauseAudioRecord {
    self.isStartedRecord = YES;
    [self.audioProcessor pauseAudioRecord];
}
- (void)resumeAudioRecord {
    self.isStartedRecord = NO;
    [self.audioProcessor resumeAudioRecord];
}

- (void)initNotification {
    // 拔插耳机事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChangeNoti:)
                                                     name:OSAudioSessionManager.routeChangeNoti
                                                   object:nil];
    // 闹铃等中断事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(InterruptionNoti:)
                                                     name:OSAudioSessionManager.InterruptionNoti
                                                   object:nil];

}

// MARK: - 通知
- (void)routeChangeNoti:(NSNotification *)info {
    NSDictionary *dic = info.userInfo;
    NSLog(@"音频事件 %@",dic);
    NSNumber* reason = dic[AVAudioSessionRouteChangeReasonKey];
    switch (reason.integerValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            [self audioDeviceChanged];
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            [self audioDeviceChanged];
            break;
        default:
            break;
    }
}
- (void)audioDeviceChanged {
    //在这里暂停播放, 更改输出设备，录音时背景音需要重置。否则无法消音
    [self startVoiceProcess];
}
- (void)InterruptionNoti:(NSNotification *)info {
    NSDictionary *dic = info.userInfo;
    NSLog(@"音频中断事件 %@",dic);
    
    NSNumber* type = dic[AVAudioSessionInterruptionTypeKey];
    NSLog(@"音频中断事件 %u",type.integerValue);
    if (type.integerValue == AVAudioSessionInterruptionTypeBegan) {
        
        NSLog(@"中断开始");
        [self pauseAudioProcess];
    }else {
        NSLog(@"中断结束");
        NSNumber* optionType = dic[AVAudioSessionInterruptionOptionKey];
        if (self.isStartedMic && !self.audioProcessor.isProcessingData) {
            // 中断导致录音停止
            [self startVoiceProcess];
        }
        
        
//        if (optionType) {
//            if (optionType.integerValue == AVAudioSessionInterruptionOptionShouldResume) {
//                NSLog(@"继续播放");
//            }
//        }else {
//            NSLog(@"optionType = nil");
//        }
        
    }
   
}
@end
