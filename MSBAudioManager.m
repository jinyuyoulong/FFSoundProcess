//
//  MSBAudioManager.m
//  MSBAudio
//
//  Created by 范金龙 on 2021/1/12.
//

#import "MSBAudioManager.h"
#import <AVFoundation/AVFoundation.h>
#import <SoundProcess/SoundProcess.h>

@interface MSBAudioManager()
@property (nonatomic,strong) DCVoicePreprocess *process;
@property (nonatomic, assign)int processType;
@end
@implementation MSBAudioManager

static MSBAudioManager * _share = nil;

+ (MSBAudioManager *)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_share) {
            _share = [[MSBAudioManager alloc] init];
            _share.processType = 0;
        }
    });
    return  _share;
}
- (void)dealloc
{
    
}

#pragma mark - C functions
- (void)startManager {
    self.process = [DCVoicePreprocess createVoicePreprocess];
    [self.process init:44100 channel:1];
}

- (NSData*)preProcess:(NSData *)inputdata {
    
//    NSURL *path = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"mp3" ];
    
    NSData *outputdata;
    if (self.processType == 0) {
        return nil;
    }
    if (self.processType == 1) {
        // agc + ns
        outputdata = [self.process preProcess:inputdata
                                  inSampleCnt: (int32_t)(inputdata.length / 2)];
    } else {
        // agc
        outputdata = [self.process preProcessAgc:inputdata
                                     inSampleCnt: (int32_t)(inputdata.length / 2)];
    }
    
    return outputdata;
}

/// 开始播放
/// @param type 1 去噪音 2 其他
void openAudioCapture(int type) {
    /// 获取麦克风权限
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                             completionHandler:^(BOOL granted) {
        if (granted) {
            [[MSBAudioManager share] startManager];
            [MSBAudioManager share].processType = type;
        }
        else {
            NSLog(@"没有权限");
        }
    }];
    
}

/// 获取音频捕获的数据
/// @param msg byte 转为 string 传递


void updateAudioCaptureData(char* msg) {
    NSData *outputdata;
    
    NSData *inputData = [NSData dataWithBytes:msg length:strlen(msg)];
    
    
//    NSString *msgStr = [[NSString alloc] initWithUTF8String:msg];
//    NSData *inputData = [msgStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"inputData:%@",inputData);
    outputdata = [[MSBAudioManager share] preProcess:inputData];
    NSLog(@"outputdata:%@",outputdata);
    char *a = (char *)[outputdata bytes];
    
    audioCaptureData(a);
}
@end
