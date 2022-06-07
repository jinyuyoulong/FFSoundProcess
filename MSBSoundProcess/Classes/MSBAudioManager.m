//
//  MSBAudioManager.m
//  MSBAudio
//
//  Created by 范金龙 on 2021/1/12.
//

#import "MSBAudioManager.h"
#import <AVFoundation/AVFoundation.h>
#import "MSBAudioMacro.h"
#import "MSBAudioCompositioner.h"
#import "MSBUnityAudioCaptureInterface.h"

@interface MSBAudioManager()

@end
@implementation MSBAudioManager



+ (MSBAudioManager *)share {
    static MSBAudioManager * _share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    });
    return  _share;
}
+ (void)audioSynthesisWithDic:(NSDictionary*)infoDic handler:(void(^)(NSString * outputFilePath))handler {
    NSArray *rhythmAudioDatas = [infoDic objectForKey:@"rhythmAudioDatas"];
    
//                MSBAudioLog(@"%s-%@",__func__,infoDic);
//    路径拼接
//    NSString *leftAudioPath = [MSBAudioManager getTotalPath:[infoDic objectForKey:@"leftRhythmClipPath"]];
//    NSString *rightAudioPath = [MSBAudioManager getTotalPath:[infoDic objectForKey:@"rightRhythmClipPath"]];
//    // 背景音乐
//    NSString *sourceClip = [MSBAudioManager getTotalPath:[infoDic objectForKey:@"sourceClip"]];
    
    NSString *leftAudioPath = [infoDic objectForKey:@"leftRhythmClipPath"];
    NSString *rightAudioPath = [infoDic objectForKey:@"rightRhythmClipPath"];
    // 背景音乐
    NSString *sourceClip = [infoDic objectForKey:@"sourceClip"];
    
    
    NSMutableArray *pathArray = [[NSMutableArray alloc] init];
    NSMutableArray *positions = [[NSMutableArray alloc] init];
    if (leftAudioPath == nil|| rightAudioPath == nil || sourceClip == nil) {
        MSBAudioLog(@"json msg 字段为空");
        handler(@"");
        return;
    }
    [pathArray addObject:sourceClip];
    [positions addObject:@0];
    [rhythmAudioDatas enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *pointInfo = (NSDictionary*)obj;
        NSNumber* time = [pointInfo objectForKey:@"time"];
        // 时间转换 毫秒 转 秒
//                float timeF = time.floatValue / 1000;
//                time = @(timeF);
        BOOL status = [[pointInfo objectForKey:@"pos"] boolValue];
        if (time != nil) {
            if (!status) {
                [pathArray addObject: leftAudioPath];
            } else {
                [pathArray addObject:rightAudioPath];
            }
            [positions addObject: time];
        } else {
            MSBAudioLog(@"打鼓 time 为空");
        }
        
    }];
    [MSBAudioCompositioner mixAudioTreacManage:pathArray isHaveBackgroundAudio:YES
                              backgroundVolume:0.1
                                     positions:positions
                                       handler:^(NSString * _Nonnull outputFilePath) {
        MSBAudioLog(@"音频合成结束，上传音频操作");
        handler(outputFilePath);
    }];
}
+ (void)audioSynthesis:(NSString*)infoStr handler:(void(^)(NSString * outputFilePath))handler {
    Class class = NSClassFromString(@"UUUtility");
    if (class) {
        SEL sel = NSSelectorFromString(@"dictionaryWithJsonString:");
        if ([class respondsToSelector:sel]) {
            IMP imp = [class methodForSelector:sel];
            NSDictionary* (*function)(id,SEL, NSString*) = (void*)imp;
            NSDictionary *infoDic = function(class,sel, infoStr);
            NSArray *rhythmAudioDatas = [infoDic objectForKey:@"rhythmAudioDatas"];
            
//                MSBAudioLog(@"%s-%@",__func__,infoDic);
            NSString *leftAudioPath = [MSBAudioManager getTotalPath:[infoDic objectForKey:@"leftRhythmClipPath"]];
            NSString *rightAudioPath = [MSBAudioManager getTotalPath:[infoDic objectForKey:@"rightRhythmClipPath"]];
            // 背景音乐
            NSString *sourceClip = [MSBAudioManager getTotalPath:[infoDic objectForKey:@"sourceClip"]];
            
            NSMutableArray *pathArray = [[NSMutableArray alloc] init];
            NSMutableArray *positions = [[NSMutableArray alloc] init];
            if (leftAudioPath == nil|| rightAudioPath == nil || sourceClip == nil) {
                MSBAudioLog(@"json msg 字段为空");
                handler(@"");
                return;
            }
            [pathArray addObject:sourceClip];
            [positions addObject:@0];
            [rhythmAudioDatas enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *pointInfo = (NSDictionary*)obj;
                NSNumber* time = [pointInfo objectForKey:@"time"];
                // 时间转换 毫秒 转 秒
//                float timeF = time.floatValue / 1000;
//                time = @(timeF);
                BOOL status = [[pointInfo objectForKey:@"pos"] boolValue];
                if (time) {
                    if (!status) {
                        [pathArray addObject: leftAudioPath];
                    } else {
                        [pathArray addObject:rightAudioPath];
                    }
                    [positions addObject: time];
                } else {
                    MSBAudioLog(@"打鼓 time 为空");
                }
                
            }];
            [MSBAudioCompositioner mixAudioTreacManage:pathArray isHaveBackgroundAudio:YES
                                      backgroundVolume:0.1
                                             positions:positions
                                               handler:^(NSString * _Nonnull outputFilePath) {
                MSBAudioLog(@"音频合成结束，上传音频操作");
                handler(outputFilePath);                
            }];
        }
    }
}
+(NSString*)getTotalPath:(NSString*)path {
    NSString * filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSURL *documentDirURL = [NSURL URLWithString:filePath];
    NSURL *respath = [documentDirURL URLByAppendingPathComponent:path];
    return respath.path;
}
@end
