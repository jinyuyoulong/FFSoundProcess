//
//  MSBAudioConvertor.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/18.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define kNumberQueueBuffers 3

typedef NS_ENUM(NSInteger, MSBAudioConvertorReleaseMethod) {
    MSBAudioConvertorReleaseMethodAudioUnit,
    MSBAudioConvertorReleaseMethodAudioQueue,
};

NS_ASSUME_NONNULL_BEGIN
@class MSBAudioConvertor;

@protocol MSBAudioConvertorDelegate

-(void)onRecorder:(MSBAudioConvertor *)aRecorder didGetQueueData:(Byte *)bytes withSize:(int) size;

@end

@interface MSBAudioConvertor : NSObject
{
    AudioStreamBasicDescription     dataFormat;

    BOOL                            isRunning;
    UInt64                          startTime;
    Float64                         hostTime;
    
    //state for voice memo
    NSString *                      mRecordFilePath;
    AudioFileID                     mRecordFile;
    SInt64                          mRecordPacket;      // current packet number in record file
    BOOL                            mNeedsVoiceDemo;
    
    // AudioQueue
    AudioQueueRef                   mQueue;
    AudioQueueBufferRef             mBuffers[kNumberQueueBuffers];
    
    // AudioUnit
    @public
    AudioUnit                        _audioUnit;
    AudioBufferList                 *_buffList;
}
@property (nonatomic ,assign)       id<MSBAudioConvertorDelegate>          delegate;
@property (readonly)                BOOL                            isRunning;
@property (readonly)                UInt64                          startTime;
@property (readonly)                AudioStreamBasicDescription     dataFormat;
@property (readonly)                AudioQueueRef                   mQueue;
@property (readonly)                BOOL                            isRecordingVoiceMemo;
@property (nonatomic ,retain)       NSString*                       rawFilePath;

@property (nonatomic ,assign)       Float64                         hostTime;
@property (nonatomic ,assign)       AudioFileID                     mRecordFile;
@property (nonatomic ,assign)       SInt64                          mRecordPacket;
@property (readonly)                BOOL                            needsVoiceDemo;

// Volume
@property (nonatomic, assign)       float                           volLDB;
@property (nonatomic, assign)       float                           volRDB;

// 区分使用AudioQueue或AudioUnit
@property (nonatomic, assign)       MSBAudioConvertorReleaseMethod        releaseMethod;

-(id)initWithFormatID:(UInt32)formatID;
-(BOOL)isRunning;

-(void)startVoiceDemo;
-(void)stopVoiceDemo;


// AudioQueue
- (void)startAudioQueueRecorder;
- (void)stopAudioQueueRecorder;


// AudioUnit
- (void)startAudioUnitRecorder;
- (void)stopAudioUnitRecorder;

// 音频转换 wav -> mp3
+ (void)convertPCMToMp3:(NSString *)pcmFilePath
                success:(void(^)(NSString *mp3Path))success
                failure:(void(^)(NSError *error))failure ;
+ (void)convertM4AToMp3:(NSString *)pcmFilePath
                success:(void(^)(NSString *mp3Path))success
                failure:(void(^)(NSError *error))failure ;
@end

NS_ASSUME_NONNULL_END
