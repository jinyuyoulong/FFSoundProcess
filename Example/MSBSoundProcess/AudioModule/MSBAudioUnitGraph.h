//
//  MSBAudioUnitGraph.h
//  MSBMediaModule
//
//  Created by 李响 on 2021/4/6.

// 实时录音耳反功能

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class MSBAudioUnitGraph;
@protocol MSBAudioUnitGraphDelegate <NSObject>

- (void)audioCaptureGetDataCallback:(const MSBAudioUnitGraph *)auGraph audioData:(NSData*)data;

@end
@interface MSBAudioUnitGraph : NSObject

/**
 如果设置此属性路径则 会写入文件到此路径 否则不写入文件
 [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"aa.pcm"]
 */
@property (nonatomic, copy, nullable) NSString *filePath;
@property (nonatomic, weak)id <MSBAudioUnitGraphDelegate> delegate;

- (void)startaudioUnitRecordAndPlay;
- (void)stopAudioUnitStop;

@end

NS_ASSUME_NONNULL_END
