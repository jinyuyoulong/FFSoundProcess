//
//  MSBAudioManager.h
//  MSBAudio
//
//  Created by 范金龙 on 2021/1/12.
//

#import <Foundation/Foundation.h>
#import <SoundProcess/SoundProcess.h>
NS_ASSUME_NONNULL_BEGIN

@interface MSBAudioManager : NSObject
/// 音频合成
/// @param infoStr 打点信息
+ (void)audioSynthesisWithDic:(NSDictionary*)infoDic handler:(void(^)(NSString * outputFilePath))handler;
/// 音频合成
/// @param infoStr 打点信息
+ (void)audioSynthesis:(NSString*)infoStr handler:(void(^)(NSString * outputFilePath))handler;
@end

NS_ASSUME_NONNULL_END

