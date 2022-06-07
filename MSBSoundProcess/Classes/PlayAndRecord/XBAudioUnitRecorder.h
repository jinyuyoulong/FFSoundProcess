//
//  XBAudioUnitRecorder.h
//  XBVoiceTool
//
//  Created by xxb on 2018/6/28.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header_audio.h"
#import "MSBAudioCapture.h"

static int m_isRecording = 0;
@class XBAudioUnitRecorder;

/** MSBAudioCapture callback audioData */
@protocol XBAudioUnitRecorderDelegate <NSObject>
- (void)captureOutput:(nullable XBAudioUnitRecorder *)capture audioData:(nullable AudioBufferList *)audioData;
- (void)captureOutput:(nullable XBAudioUnitRecorder *)capture  ioActionFlags:(AudioUnitRenderActionFlags*) ioActionFlags  inTimeStamp:(const AudioTimeStamp *)inTimeStamp inBusNumber:(UInt32)inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData;
@end

typedef void (^XBAudioUnitRecorderOnputBlock)(AudioBufferList *bufferList);
typedef void (^XBAudioUnitRecorderOnputBlockFull)(XBAudioUnitRecorder *player,
                                                AudioUnitRenderActionFlags *ioActionFlags,
                                                const AudioTimeStamp *inTimeStamp,
                                                UInt32 inBusNumber,
                                                UInt32 inNumberFrames,
                                                AudioBufferList *ioData);

@interface XBAudioUnitRecorder : NSObject
@property (nonatomic,readonly,assign) BOOL isRecording;
@property (nonatomic,assign) int m_preferredBufferSize; //录音缓冲区长度;
@property (nonatomic,copy) XBAudioUnitRecorderOnputBlock bl_output;
@property (nonatomic,copy) XBAudioUnitRecorderOnputBlockFull bl_outputFull;
@property (nonatomic,strong) NSLock * m_lock_recode;                 //recode_lock;
@property (nullable, nonatomic, weak) id<XBAudioUnitRecorderDelegate> delegate;

- (instancetype)initWithRate:(XBAudioRate)rate bit:(XBAudioBit)bit channel:(XBAudioChannel)channel Preferretime:(int)preferretime;
- (void)start;
- (void)stop;
- (AudioStreamBasicDescription)getOutputFormat;
- (void)setpreferre:(int)preferretime; //设置录音缓冲区长度;
@end
