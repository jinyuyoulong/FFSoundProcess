//
//  FFAudio.h
//  AudioQueueCaptureOC
//
//  Created by 范金龙 on 2021/1/16.
//

#import <Foundation/Foundation.h>
#import <MSBSoundProcess/MSBAudioManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface FFAudio : NSObject
@property (nonatomic, strong)MSBAudioManager *audioProcesser;
@property (nonatomic, assign)BOOL isStartPlay;

// 播放的数据流数据
- (void)playWithData:(NSData *)data;

// 声音播放出现问题的时候可以重置一下
- (void)resetPlay;

// 停止播放
- (void)stop;
@end

NS_ASSUME_NONNULL_END
