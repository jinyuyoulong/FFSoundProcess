//
//  MSBAudioCompositioner.m
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/22.
//

#import "MSBAudioCompositioner.h"
#import <AVFoundation/AVFoundation.h>
#import "MSBAudioMacro.h"
#import "MSBAudioConvertor.h"
#import "MSBUnityAudioCaptureInterface.h"

@interface MSBAudioCompositioner ()

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, copy) NSString *filePath;

@end

@implementation MSBAudioCompositioner
+ (NSString *)filePath {
    // 判断输入路径是否存在
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString * filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *fileName = [filePath stringByAppendingPathComponent:kAudioFileName];
    if (![fm fileExistsAtPath:fileName])
    {
        MSBAudioLog(@"文件目录不存在");
        BOOL isCreateSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:fileName
                                                         withIntermediateDirectories:YES
                                                                          attributes:nil
                                                                               error:nil];
        filePath = (isCreateSuccess) ? [fileName stringByAppendingPathComponent:kAudioMusicName] : @"";
    } else {
        filePath = [fileName stringByAppendingPathComponent:kAudioMusicName];
    }
    
    return filePath;
}
+ (void)audioSynthesis:(NSArray*)names
       backgroundAudio:(NSString*)backgroundPath
             positions:(NSArray<NSNumber*>*)positions
               handler:(void (^)(NSString* outputFilePath))handler {
    NSMutableArray *pathArray = [NSMutableArray array];
    NSMutableArray *allPaths = [[NSMutableArray alloc] initWithObjects:backgroundPath, nil];
    NSMutableArray *mpositions = [[NSMutableArray alloc] initWithObjects:@0, nil];
    [allPaths addObjectsFromArray:names];
    [mpositions addObjectsFromArray:positions];
    // 加载音频源
    for (int i = 0; i < allPaths.count; i++) {
        NSInteger index = i;
        NSString *name = allPaths[index];
        NSArray *items = [name componentsSeparatedByString:@"."];
        NSString *audioNameAndPath = items[0];
        NSString *audioType = items[1];
        NSString *path = [[NSBundle mainBundle] pathForResource:audioNameAndPath ofType:audioType];
//        NSString *path = [[NSBundle mainBundle] pathForResource:allPaths[index] ofType:@"mp3"];
        [pathArray addObject:path];
    }
    
    // 多音轨处理
    [self mixAudioTreacManage:pathArray
         isHaveBackgroundAudio:YES
             backgroundVolume:0.1
                     positions:mpositions
                       handler:^(NSString *outputFilePath) {
        handler(outputFilePath);
    }];
}
/// 音频合成无背景音
+ (void)audioSynthesis:(NSArray*)names
             positions:(NSArray<NSNumber*>*)positions
               handler:(void (^)(NSString* outputFilePath))handler {

    NSMutableArray *pathArray = [NSMutableArray array];
    
    // 加载音频源
    for (int i = 0; i < names.count; i++) {
        NSInteger index = i;
//        NSString *path = [[NSBundle mainBundle] pathForResource:names[index] ofType:@"mp3"];
        NSString *name = names[index];
        NSArray *items = [name componentsSeparatedByString:@"."];
        NSString *audioNameAndPath = items[0];
        NSString *audioType = items[1];
        NSString *path = [[NSBundle mainBundle] pathForResource:audioNameAndPath ofType:audioType];
        if (path) {
            [pathArray addObject:path];
        }
    }
    
    // 多音轨处理
    [self mixAudioTreacManage:pathArray isHaveBackgroundAudio:NO backgroundVolume:0
                     positions:positions handler:^(NSString *outputFilePath) {
        handler(outputFilePath);
    }];
    
    //单音轨合并处理
//    [MSBAudioCompositioner singelAudioTrackProcess:pathArray positions:positions handler:^(NSString *outputFilePath) {
//        handler(outputFilePath);
//    }];
    
}

/// 单音轨合成，目前会有余音问题
+ (void)singelAudioTrackProcess:(NSArray<NSString*>*)pathArray
                           positions:(NSArray<NSNumber*>*)positions
                             handler:(void (^)(NSString* outputFilePath))handler {
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    //单音轨合并处理
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                     preferredTrackID:0];
    
    __block CMTime beginTime = kCMTimeZero;
    __block NSError *error = nil;
    
    [pathArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //2.拿到音频资源
        AVURLAsset *audioAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:obj] options:nil];
        //需要合并的音频文件播放区间
//        CMTime audioAssetduration = [self makeCTTime:(Float64)(audioAsset.duration.value/audioAsset.duration.timescale)/2];
//        CMTimeRange audioRange = CMTimeRangeMake(kCMTimeZero, audioAssetduration);
        CMTimeRange audioRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        //添加音频到音轨中
        BOOL success = [audioTrack insertTimeRange:audioRange
                                      ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                       atTime:beginTime
                                        error:&error];
        if (!success) {
            MSBAudioLog(@"合成失败：%@",error);
            return ;
        }
        //记录下次的开始时间（这一段尾部）
//        CMTime duration = [self makeCTTime:(Float64)(positions[idx].floatValue)];
//        CMTime tmpTime = [self makeCTTime:(Float64)(beginTime.value/beginTime.timescale)/2];
//        CMTime duration = [self makeCTTime:(Float64)(audioAsset.duration.value/audioAsset.duration.timescale)/2];
//        beginTime = CMTimeAdd(beginTime, CMTimeMake(1, 1));
        CMTime duration = audioAsset.duration;
        beginTime = CMTimeAdd(beginTime, duration);
//        beginTime = CMTimeAdd(beginTime, audioAsset.duration);
    }];
    
    // 合并后的文件导出 - `presetName`要和之后的`session.outputFileType`相对应。
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = [[self.filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:kAudioMusicName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutFilePath error:nil];
    }
    
    // 查看当前session支持的fileType类型
    MSBAudioLog(@"supportedFileTypes---%@",[session supportedFileTypes]);
    
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A; //与上述的`present`相对应
    session.shouldOptimizeForNetworkUse = YES;   //优化网络
//    CMTime startTime = CMTimeMake(0, 1);
//    CMTime endTime = CMTimeMake(13, 1);
//    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, endTime);
//    session.timeRange = exportTimeRange;// 裁剪
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            MSBAudioLog(@"合并音频成功----%@", outPutFilePath);
            handler(outPutFilePath);
        } else {
            // 其他情况, 具体请看这里`AVAssetExportSessionStatus`.
            MSBAudioLog(@"合并音频失败status:----%ld", session.status);
            handler(@"");
        }
    }];
}

+ (void)mixAudioTreacManage:(NSArray<NSString*>*)pathArray
       isHaveBackgroundAudio:(BOOL)isHaveBackgroundAudio
           backgroundVolume:(float)backgroundVolume
                   positions:(NSArray<NSNumber*>*)positions
                     handler:(void (^)(NSString* outputFilePath))handler {
    MSBAudioLog(@"mixAudioTreacProcess befor pathArray=%@\npositions=%@",pathArray,positions);
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    NSMutableArray *audioAssetArray = [NSMutableArray array];
    NSMutableArray *audioTrackArray = [NSMutableArray array];
    NSMutableArray *audioAssetTrackArray = [NSMutableArray array];

    // 加载音频源
    for (int i = 0; i < pathArray.count; i++) {
        NSInteger index = i;
        NSString *path = [pathArray objectAtIndex:index];
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
        BOOL result = [audioAsset isPlayable];
        if (!result) {
            MSBAudioLog(@"audioAsset isPlayable=false");
            continue;
        }
        //添加一个音频轨道并返回
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        MSBAudioLog(@"audioAsset=%@",audioAsset);
        MSBAudioLog(@"audioTrack=%@",audioTrack);
        MSBAudioLog(@"audioAssetTrack=%@",audioAssetTrack);
        if (!audioTrack) {
            
        }
        [audioAssetArray addObject:audioAsset];
        [audioTrackArray addObject:audioTrack];
        [audioAssetTrackArray addObject:audioAssetTrack];
    }
    
    BOOL result =  [MSBAudioCompositioner mixAudioTreacProcess:audioAssetArray
                                audioTrackArray:audioTrackArray
                           audioAssetTrackArray:audioAssetTrackArray
                                      pathArray:pathArray
                                      positions:positions];
    if (!result) {
        handler(@"");
        return;
    }
    AVMutableAudioMix *videoAudioMixTools = nil;
    if (isHaveBackgroundAudio) {
        videoAudioMixTools = [MSBAudioCompositioner setVolumeRamp:pathArray
                                                audioAssetArray:audioAssetArray
                                                audioTrackArray:audioTrackArray
                                           audioAssetTrackArray:audioAssetTrackArray
                                                    startVolume:backgroundVolume
                                                      toEndVolume:backgroundVolume];
    }
    
    [MSBAudioCompositioner exportAsynchronously:composition
                             videoAudioMixTools:videoAudioMixTools
                          WithCompletionHandler:handler];
}
+ (AVMutableAudioMix *)setVolumeRamp:(NSArray<NSString*>*)allPaths
                                    audioAssetArray:(NSMutableArray *)audioAssetArray
                                    audioTrackArray:(NSMutableArray *)audioTrackArray
                               audioAssetTrackArray:(NSMutableArray *)audioAssetTrackArray
                                        startVolume:(float)startVolume
                                        toEndVolume:(float)endVolume {
    AVMutableAudioMix *videoAudioMixTools = [AVMutableAudioMix audioMix];
    NSMutableArray * params = [[NSMutableArray alloc] initWithCapacity:0];
    
    __block CMTime beginTime = kCMTimeZero;
    __block NSError *error = nil;
    [allPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVURLAsset *audioAsset = audioAssetArray[idx];
        AVMutableCompositionTrack *audioTrack = audioTrackArray[idx];
        AVAssetTrack *audioAssetTrack = audioAssetTrackArray[idx];
        
        if (idx == 0) {
            //调节音量
            //获取音频轨道
            AVMutableAudioMixInputParameters *firstAudioParam = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
            //设置音轨音量,可以设置渐变,设置为1.0就是全音量
            [firstAudioParam setVolumeRampFromStartVolume:startVolume
                                              toEndVolume:endVolume
                                                timeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration)];
            [firstAudioParam setTrackID:audioTrack.trackID];
            [params addObject:firstAudioParam];
        }
    }];

    videoAudioMixTools.inputParameters = [NSArray arrayWithArray:params];
    return  videoAudioMixTools;
}
+ (BOOL)mixAudioTreacProcess:(NSMutableArray *)audioAssetArray
             audioTrackArray:(NSMutableArray *)audioTrackArray
        audioAssetTrackArray:(NSMutableArray *)audioAssetTrackArray
                   pathArray:(NSArray<NSString*>*)pathArray
                   positions:(NSArray<NSNumber*>*)positions {
    MSBAudioLog(@"audioAssetArray.count=%ld pathArray.count=%ld",audioAssetArray.count, pathArray.count);
    if (audioAssetArray.count != pathArray.count) {
        MSBAudioLog(@"音轨数据和打点数据不匹配！不做合成");
        return NO;
    }
    __block CMTime beginTime = kCMTimeZero;
    __block NSError *error = nil;
    [pathArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVURLAsset *audioAsset = audioAssetArray[idx];
        AVMutableCompositionTrack *audioTrack = audioTrackArray[idx];
        AVAssetTrack *audioAssetTrack = audioAssetTrackArray[idx];

        Float64 position = [positions[idx] doubleValue]/1000;
//        Float64 position = [positions[idx] doubleValue];
        MSBAudioLog(@"position:%lf",position);
        MSBAudioLog(@"pathArray.obj:%@",obj);
        CMTimeRange audioRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
//        CMTime duration = [self makeCTTime:position];
        beginTime = [self makeCTTime:position];
//        beginTime = CMTimeAdd(beginTime, duration);
        
        [audioTrack insertTimeRange:audioRange
                            ofTrack:audioAssetTrack
                             atTime:beginTime
                              error:&error];
    }];
    return YES;
}
// MARK: - 开始合成音频
+ (void)exportAsynchronously:(AVMutableComposition*)composition
          videoAudioMixTools:(AVMutableAudioMix*)videoAudioMixTools
       WithCompletionHandler:(void (^)(NSString* outputFilePath))handler {
    // 合并后的文件导出 - `presetName`要和之后的`session.outputFileType`相对应。
//    kAudioMusicName
    NSString *savefilename = [NSString stringWithFormat:@"%@%@",[self getNowTimeTimestamp],@".m4a"];
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = [[self.filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:savefilename];
    MSBAudioLog(@"音频文件路径：%@",outPutFilePath);
    //删除已存在的音频文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutFilePath]) {
        MSBAudioLog(@"删除已存在的音频文件");
        [[NSFileManager defaultManager] removeItemAtPath:outPutFilePath error:nil];
    }
    
    // 查看当前session支持的fileType类型
    MSBAudioLog(@"supportedFileTypes：---%@",[session supportedFileTypes]);
    
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A; //与上述的`present`相对应
    session.shouldOptimizeForNetworkUse = YES;   //优化网络
    if (videoAudioMixTools) {
        session.audioMix = videoAudioMixTools;
    }
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            MSBAudioLog(@"合并音频成功----%@", outPutFilePath);
            [MSBAudioConvertor convertM4AToMp3:outPutFilePath
                                       success:^(NSString * _Nonnull mp3Path) {
                MSBAudioLog(@"音频格式转换成功----%@", mp3Path);
                handler(mp3Path);
            } failure:^(NSError * _Nonnull error) {
                MSBAudioLog(@"音频格式转换失败----%@", error);
                handler(@"");
            }];
            
        } else {
            // 其他情况, 具体请看这里`AVAssetExportSessionStatus`.
            MSBAudioLog(@"合并音频失败status:----%ld", session.status);
            handler(@"");
        }
    }];
}
// MARK: - 音频裁剪
/// 音频裁剪
/// @param url <#url description#>
/// @param startTime <#startTime description#>
/// @param endTime <#endTime description#>
/// @param outputPath <#outputPath description#>
+ (void)audioCrop:(NSURL *)url startTime:(CMTime)startTime endTime:(CMTime)endTime outputPath:(NSString*)outputPath {
    NSURL *audioFileOutput = [NSURL fileURLWithPath:outputPath];
    
    [[NSFileManager defaultManager] removeItemAtURL:audioFileOutput error:NULL];
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset
                                                                            presetName:AVAssetExportPresetAppleM4A];
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, endTime);
    
    exportSession.outputURL = audioFileOutput;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    exportSession.timeRange = exportTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (AVAssetExportSessionStatusCompleted == exportSession.status) {
            MSBAudioLog(@" FlyElephant \n %@", outputPath);
        } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
            MSBAudioLog(@"FlyElephant error: %@", exportSession.error.localizedDescription);
        }
    }];
}
// MARK: - tools func
+ (CMTime )makeCTTime:(Float64)senconds {
    int32_t preferredTimeScale = 44100;
    CMTime audioTime = CMTimeMakeWithSeconds(senconds, preferredTimeScale);
    return audioTime;
}
+(NSString *)getNowTimeTimestamp{

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;

    [formatter setDateStyle:NSDateFormatterMediumStyle];

    [formatter setTimeStyle:NSDateFormatterShortStyle];

    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制

    //设置时区,这个对于时间的处理有时很重要

    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];

    [formatter setTimeZone:timeZone];

    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式

    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];

    return timeSp;

}
@end
