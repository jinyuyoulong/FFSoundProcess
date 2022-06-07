//
//  MSBAudioCompositioner.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSBAudioCompositioner : NSObject
+ (void)audioSynthesis:(NSArray*)names positions:(NSArray<NSNumber*>*)positions
               handler:(void (^)(NSString* outputFilePath))handler;

/// 多音轨合成
/// @param names 素材名称
/// @param backgroundName 背景音名称
/// @param positions 各音轨start时间 毫秒
/// @param handler 成功回调
+ (void)audioSynthesis:(NSArray*)names
       backgroundAudio:(NSString*)backgroundName
             positions:(NSArray<NSNumber*>*)positions
               handler:(void (^)(NSString* outputFilePath))handler;

/// 单音轨合成，目前会有余音问题
/// @param pathArray 音频路径
/// @param positions 音频开始时间 -秒-
/// @param handler 完成回调
+ (void)singelAudioTrackProcess:(NSArray<NSString*>*)pathArray
                           positions:(NSArray<NSNumber*>*)positions
                        handler:(void (^)(NSString* outputFilePath))handler;

/// 多音轨合成带背景音
/// @param pathArray 音频路径数组
/// @param isHaveBackgroundAudio 是否有背景音
/// @param backgroundVolume 背景音音量 0 ~ 1.0 之间
/// @param positions 音频间隔时长数组，数量和path保持一致
/// @param handler 合成成功回调
+ (void)mixAudioTreacManage:(NSArray<NSString*>*)pathArray
       isHaveBackgroundAudio:(BOOL)isHaveBackgroundAudio
           backgroundVolume:(float)backgroundVolume
                   positions:(NSArray<NSNumber*>*)positions
                    handler:(void (^)(NSString* outputFilePath))handler;
@end

NS_ASSUME_NONNULL_END
