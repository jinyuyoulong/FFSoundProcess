//
//  MSBAudioManager.h
//  MSBAudio
//
//  Created by 范金龙 on 2021/1/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSBAudioManager : NSObject

@end

#if defined(__cplusplus)
extern "C" {
#endif

/// 开启捕获某个音频设备
/// @param type 开启模式 1 去噪音 2 其他
void openAudioCapture(int type);

/// 获取音频捕获的数据
/// @param msg 数据地址
void audioCaptureData(char* msg);

/// 发送采样数据到Native层
/// @param msg 数据地址
void updateAudioCaptureData(char* msg);

#if defined(__cplusplus)
}
#endif

NS_ASSUME_NONNULL_END

