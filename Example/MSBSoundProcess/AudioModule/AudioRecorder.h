//
//  AudioRecorder.h
//  AudioQueueCaptureOC
//
//  Created by 范金龙 on 2021/1/16.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
@class AudioRecorder;
@protocol AudioRecorderDelegate <NSObject>

- (void)captureOutput:(nullable AudioRecorder *)capture audioData:(nullable NSData*)audioData;


@end
@interface AudioRecorder : NSObject
@property (nonatomic, weak)id<AudioRecorderDelegate> delegate;
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) AVAudioSessionPort audioSessionPort;
@property (nonatomic, assign) BOOL running;

+ (AudioRecorder*)defaultInstance;

//开始录音
- (void)startRecording;

//停止录音
- (void)stopRecording;
@end

NS_ASSUME_NONNULL_END
