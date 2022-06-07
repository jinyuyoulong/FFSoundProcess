//
//  XBAudioPlayAndRecoder.h
//  SoundProcessIosDemo
//
//  Created by 朱韦刚 on 2021/8/19.
//

#import <Foundation/Foundation.h>
#import "Header_audio.h"
#import "XBAudioPCMDataReader.h"

#ifndef XBAudioPlayAndRecoder_h
#define XBAudioPlayAndRecoder_h

@class XBAudioUnitPlayAndRecorder;

//recode;
typedef void (^XBAudioUnitPLayRecorderOnputBlock)(AudioBufferList *bufferList);
typedef void (^XBAudioUnitPlayRecorderOnputBlockFull)(XBAudioUnitPlayAndRecorder *recoder,
                                                AudioUnitRenderActionFlags *ioActionFlags,
                                                const AudioTimeStamp *inTimeStamp,
                                                UInt32 inBusNumber,
                                                UInt32 inNumberFrames,
                                                AudioBufferList *ioData);

//player;
typedef void (^XBAudioUnitPLayRecorderInputBlock)(AudioBufferList *bufferList);
typedef void (^XBAudioUnitPLayRecorderInputBlockFull)(XBAudioUnitPlayAndRecorder *player,
                                                AudioUnitRenderActionFlags *ioActionFlags,
                                                const AudioTimeStamp *inTimeStamp,
                                                UInt32 inBusNumber,
                                                UInt32 inNumberFrames,
                                                AudioBufferList *ioData);


@interface XBAudioUnitPlayAndRecorder : NSObject
//recode;
@property (nonatomic,copy) XBAudioUnitPLayRecorderOnputBlock bl_output;
@property (nonatomic,copy) XBAudioUnitPlayRecorderOnputBlockFull bl_outputFull;
@property (nonatomic,readonly,assign) BOOL isRecording;
//player;
@property (nonatomic,copy) NSString *filePath;
@property (nonatomic,strong) NSData *dataStore;
@property (nonatomic,strong) XBAudioPCMDataReader *reader;
@property (nonatomic,copy) XBAudioUnitPLayRecorderInputBlock bl_input;
@property (nonatomic,copy) XBAudioUnitPLayRecorderInputBlockFull bl_inputFull;
@property (nonatomic,assign) BOOL isPlaying;

- (instancetype)initWithRate_palyandrecode:(NSString *)playfilePath rate:(XBAudioRate)rate bit:(XBAudioBit)bit channel:(XBAudioChannel)channel;
- (void)start;
- (void)stop;
- (int)getinputLatency;
@end


#endif /* XBAudioPlayAndRecoder_h */
