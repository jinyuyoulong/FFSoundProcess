//
//  MSBAudioInterface.m
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/7/1.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import "MSBAudioInterface.h"
#import <AVFoundation/AVFoundation.h>
#import <MSBSoundProcess/MSBSoundProcessHeader.h>
#import <MSBSoundProcess/MSBAudioKitInterface.h>

@interface MSBAudioInterface ()<MSBAudioKitInterface>
@property (nonatomic, strong)UITextView *textView;

@end
@implementation MSBAudioInterface
+(MSBAudioInterface*)shared {
    static MSBAudioInterface *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[MSBAudioInterface alloc]init];
    });
    return _shared;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        MSBUnityAudioCaptureInterface.shared.islog = true;
//        MSBAudioCaptureManager.share.delegate = self;
//        [UIApplication.sharedApplication.keyWindow addSubview:self.textView];
//        [UIApplication.sharedApplication.keyWindow bringSubviewToFront:self.textView];
    }
    return self;
}
//- (UITextView* )textView
//{
//    if(!_textView){
//        _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 300, 100, 100)];
//        _textView.text = @"xss";
//    }
//    return _textView;
//}
//- (void)processedAudioWithPitch:(MSBVoiceAnalysisInfo *)analysisInfo {
//    MSBVoicePitchInfo *pitchinfo = analysisInfo.pitchSeq.lastObject;
//    MSBVoiceVadInfo *vadinfo = analysisInfo.vadResult.lastObject;
//    MSBVoiceNoteInfo *noteinfo = analysisInfo.noteSeq.lastObject;
//    NSString *pitchStr;
//    NSString *vadStr;
//    NSString *noteStr;
//    if (!analysisInfo ||analysisInfo.pitchSeq.count == 0 || !pitchinfo) {
//        pitchStr = @"0,0,0,0,0";
//    } else {
//        pitchStr = [NSString stringWithFormat:@"%d,%d,%d,%d,%f",pitchinfo.startTimeMs,
//                    pitchinfo.endTimeMs,pitchinfo.startFrameIndex,pitchinfo.endFrameIndex,pitchinfo.freq];
//    }
//    NSLog(@"音频处理结果音高pitch：%f",pitchinfo.freq);
//    if (!analysisInfo || analysisInfo.vadResult.count == 0 || !vadinfo) {
//        vadStr = @"0,0";
//    } else {
//        vadStr = [NSString stringWithFormat:@"%d,%d",vadinfo.timeMs,vadinfo.vocal ? 1: 0];
//    }
//    if (!analysisInfo || analysisInfo.noteSeq.count == 0 || !noteinfo) {
//        noteStr = @"0,0,0,0,0";
//    } else {
//        noteStr = [NSString stringWithFormat:@"%d,%d,%d,%d,%f",noteinfo.startTimeMs,
//                   noteinfo.endTimeMs,noteinfo.startFrameIndex,noteinfo.endFrameIndex,noteinfo.note];
//    }
//
//    // unity send message
//    NSString *result = [NSString stringWithFormat:@"%@&%@&%@",vadStr, pitchStr, noteStr];
//    NSLog(@"音频处理结果：%@",result);
////    [MSBAudioInterface OnResponseVoiceProcess:result];
//    // 歌唱对对碰 音频处理回调
//
////    非洲鼓识别值：
////    是否有声音：1
////    pitch值：
////    中间区域范围：80-100
////    两边区域：170加减10、350加减10、400加减10、500加减10、
//    if (vadinfo.vocal) {
//        float pitch = pitchinfo.freq;
//        NSString *infoMsg = @"";
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *contentText = self.textView.text;
//            self.textView.text = [NSString stringWithFormat:@"pitch=%f\n%@\n",pitch,contentText];
//        });
//
//
//        if (pitch>=80 && pitch <=100) {
//            NSLog(@"非洲鼓中间区域");
//            infoMsg = @"非洲鼓中间区域";
////            NSString *contentText = self.textView.text;
////            self.textView.text = [NSString stringWithFormat:@"%@\n%@\n",@"非洲鼓中间区域",contentText];
//        }
//        if ([self checkNumber:pitch InArea:170 edgeNum:10]
//            || [self checkNumber:pitch InArea:350 edgeNum:10]
//            || [self checkNumber:pitch InArea:400 edgeNum:10]
//            || [self checkNumber:pitch InArea:500 edgeNum:10]) {
//            NSLog(@"非洲鼓两边区域");
//            infoMsg = @"非洲鼓中间区域";
//        }
////        dispatch_async(dispatch_get_main_queue(), ^{
//            [NSNotificationCenter.defaultCenter postNotificationName:@"AudioKit"
//                                                              object:nil
//                                                        userInfo:@{@"data":[NSString stringWithFormat:@"%f",pitch]}];
////        });
////        UnitySendMessage("CrossPlatform","OnResponseVoiceProcess", [result UTF8String]);
//    }
//
//}
//- (BOOL)checkNumber:(float)num InArea:(float)areaNum edgeNum:(float)edgeNum {
//    if (num >= (areaNum-edgeNum) && num <=(areaNum+edgeNum)) {
//        return true;
//    }
//    return false;
//}
//// 转换mp3完成之后的回调方法
//- (void)recordAudioFileFinish:(NSString *)mp3Path {
////    UnitySendMessage("CrossPlatform", "RecordAudioFileFinish",[mp3Path UTF8String]);
//}
@end
