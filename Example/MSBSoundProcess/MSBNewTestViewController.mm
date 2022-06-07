//
//  MSBNewTestViewController.m
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/10/13.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import "MSBNewTestViewController.h"

#import <SoundProcess/SoundProcess.h>

//aec_test;播放器;
#import "XBPCMPlayer.h"
#import "XBAudioTool.h"
#import "XBAudioPlayer.h"
#import "XBAudioPCMDataReader.h"
#import "XBDataWriter.h"
#import "XBExtAudioFileRef.h"

//aec_test;recode;
#import "XBAudioUnitRecorder.h"
#import "XBAudioPlayAndRecoder.h"
#include <string>
#include <map>
#include <vector>
#include <queue>


#import <MSBSoundProcess/MSBUnityAudioCaptureInterface.h>

@interface MSBNewTestViewController ()
@end

#define filepath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"record.pcm"]

static std::vector<std::string> m_ScaleName;        //88个键，例如4C;
static std::vector<NSString *> m_percentage_vector; //录音过滤稳定用的百分比vector;

@implementation MSBNewTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 消息通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil]; //监听是否触发home键挂起程序.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil]; //监听是否重新进入程序程序.
}
#define aec_subPathPCM_far @"/Documents/test_aec_far.pcm"
#define aec_stroePath_far [NSHomeDirectory() stringByAppendingString:aec_subPathPCM_far]
#define aec_subPathPCM_near @"/Documents/test_aec_near.pcm"
#define aec_stroePath_near [NSHomeDirectory() stringByAppendingString:aec_subPathPCM_near]
// 去除背景音后识别音频
- (IBAction)play:(id)sender {
    NSString * path = [[NSBundle mainBundle] pathForResource:@"nixiaoqilaizhenhaokna_44100_1_s16"
                                                      ofType:@"mp3"];
    [MSBUnityAudioCaptureInterface.shared startCaptureWithBgMusic:path];
//    [MSBUnityAudioCaptureInterface.shared startAudioCapture:0];
}
- (IBAction)stopPlay:(id)sender {
    [MSBUnityAudioCaptureInterface.shared stopAudioCapture:0];
//    [MSBUnityAudioCaptureInterface.shared stopAudioProcess];
}
- (IBAction)startRecord:(id)sender {
//    [self cameraView_startOrStopRecordVideo];
//    [self.audioProcessor onlyStartRecordAndProcessAudioData];
//    [self.audioProcessor startRecord];
}
- (IBAction)stopRecord:(id)sender {
//    [self stopcameraView_startOrStopRecordVideo];
//    [self.audioProcessor onlyStopRecordAndProcessAudioData];
//    [self.audioProcessor stopRecord];
}

#pragma mark - 消息通知
//挂起;
- (void)applicationWillResignActive:(NSNotification *)notification{
    NSLog(@"挂起");
    [MSBUnityAudioCaptureInterface.shared pauseAudioProcess];
}

//返回;
- (void)applicationDidBecomeActive:(NSNotification *)notification{
    NSLog(@"返回");
    [MSBUnityAudioCaptureInterface.shared resumeAudioProcess ];
}

@end
