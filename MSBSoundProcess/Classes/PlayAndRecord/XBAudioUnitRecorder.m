//
//  XBAudioUnitRecorder.m
//  XBVoiceTool
//
//  Created by xxb on 2018/6/28.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import "XBAudioUnitRecorder.h"
#import "XBAudioTool.h"
//#import <MSBSoundProcess/MSBSoundProcess-Swift.h>
//#import <OSAbility/OSAbility-umbrella.h>
@import OSAbility;

#define subPathPCM @"/Documents/xbMedia"
#define stroePath [NSHomeDirectory() stringByAppendingString:subPathPCM]

@interface XBAudioUnitRecorder ()
{
    AudioUnit audioUnit;
}
@property (nonatomic,assign) XBAudioBit bit;
@property (nonatomic,assign) XBAudioRate rate;
@property (nonatomic,assign) XBAudioChannel channel;
@property (nonatomic,assign) AudioStreamBasicDescription inputStreamDesc;
@end

@implementation XBAudioUnitRecorder

- (instancetype)initWithRate:(XBAudioRate)rate bit:(XBAudioBit)bit channel:(XBAudioChannel)channel Preferretime:(int)preferretime
{
    self.m_preferredBufferSize = preferretime;
    
    if (self = [super init])
    {
        self.bit = bit;
        self.rate = rate;
        self.channel = channel;
        
        [self initInputAudioUnitWithRate:self.rate bit:self.bit channel:self.channel];
    }
    return self;
}
- (instancetype)init
{
    if (self = [super init])
    {
        self.bit = XBAudioBit_16;
        self.rate = XBAudioRate_44k;
        self.channel = XBAudioChannel_1;
        self.m_preferredBufferSize = 0;
        
        [self initInputAudioUnitWithRate:self.rate bit:self.bit channel:self.channel];
    }
    return self;
}
- (void)dealloc
{
    //[self.m_lock_recode lock];
    //CheckError(AudioComponentInstanceDispose(audioUnit),
    //           "AudioComponentInstanceDispose failed");
    NSLog(@"XBAudioUnitRecorder销毁");
    //[self.m_lock_recode unlock];
}

- (void)initInputAudioUnitWithRate:(XBAudioRate)rate bit:(XBAudioBit)bit channel:(XBAudioChannel)channel
{
    //设置AVAudioSession
//    NSError *error = nil;
//    AVAudioSession* session = [AVAudioSession sharedInstance];
////    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth error:&error];
//    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayAndRecord
//                                          mode:AVAudioSessionModeVideoRecording
//                                       options:AVAudioSessionCategoryOptionAllowBluetoothA2DP
//     | AVAudioSessionCategoryOptionAllowBluetooth
//     | AVAudioSessionCategoryOptionAllowAirPlay
//     | AVAudioSessionCategoryOptionDefaultToSpeaker
////     | AVAudioSessionCategoryOptionDuckOthers
//                                         error:&error];
//    
//    [session setActive:YES error:nil];
    
    [OSAudioSessionManager.shared setRecordSession];
    
    
    //初始化audioUnit
    AudioComponentDescription inputDesc = [XBAudioTool allocAudioComponentDescriptionWithComponentType:kAudioUnitType_Output componentSubType:kAudioUnitSubType_RemoteIO componentFlags:0 componentFlagsMask:0];
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &inputDesc);
    CheckError(AudioComponentInstanceNew(inputComponent, &audioUnit), "AudioComponentInstanceNew failure");

    //设置输出流格式
    int mFramesPerPacket = 1;
    
    AudioStreamBasicDescription inputStreamDesc = [XBAudioTool allocAudioStreamBasicDescriptionWithMFormatID:kAudioFormatLinearPCM mFormatFlags:(kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsPacked) mSampleRate:rate mFramesPerPacket:mFramesPerPacket mChannelsPerFrame:channel mBitsPerChannel:bit];
    self.inputStreamDesc = inputStreamDesc;
    
    OSStatus status = AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         kInputBus,
                         &inputStreamDesc,
                         sizeof(inputStreamDesc));
    CheckError(status, "setProperty inputStreamFormat error");
    
    //麦克风输入设置为1（yes）
    int inputEnable = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &inputEnable,
                                  sizeof(inputEnable));
    CheckError(status, "setProperty EnableIO error");
    
    //设置回调
    AURenderCallbackStruct inputCallBackStruce;
    inputCallBackStruce.inputProc = inputCallBackFun;
    inputCallBackStruce.inputProcRefCon = (__bridge void * _Nullable)(self);
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &inputCallBackStruce,
                                  sizeof(inputCallBackStruce));
    CheckError(status, "setProperty InputCallback error");
    
    //设置缓冲区长度;
    NSLog(@"self.m_preferredBufferSize = %d",self.m_preferredBufferSize);
    if(self.m_preferredBufferSize != 0)
    {
        Float32 preferredBufferSize = 0.06; //in seconds;这个时长不是按照设置的长度的时间算的;
        int result = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,
                                         sizeof(preferredBufferSize), &preferredBufferSize);
    }
    
    AudioStreamBasicDescription outputDesc0;
    UInt32 size = sizeof(outputDesc0);
    CheckError(AudioUnitGetProperty(audioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &outputDesc0,
                                    &size),"get property failure");
    
    AudioStreamBasicDescription outputDesc1;
    size = sizeof(outputDesc1);
    CheckError(AudioUnitGetProperty(audioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &outputDesc1,
                                    &size),"get property failure");
}

- (void)start
{
    [self delete];
    AudioOutputUnitStart(audioUnit);
    _isRecording = YES;
    m_isRecording = 1;
    self.m_lock_recode = [[NSLock alloc] init];
}

- (void)stop
{
    //[self.m_lock_recode lock];
    //这里不能调用要在_isRecording之后 否则有卡死的问题;
    CheckError(AudioOutputUnitStop(audioUnit),
               "AudioOutputUnitStop failed");
    
    _isRecording = NO;
    m_isRecording = 0;
    //[self.m_lock_recode unlock];
}



- (AudioStreamBasicDescription)getOutputFormat
{
    return self.inputStreamDesc;
//    AudioStreamBasicDescription outputDesc0;
//    UInt32 size = sizeof(outputDesc0);
//    CheckError(AudioUnitGetProperty(audioUnit,
//                                    kAudioUnitProperty_StreamFormat,
//                                    kAudioUnitScope_Output,
//                                    0,
//                                    &outputDesc0,
//                                    &size),"get property failure");
//    return outputDesc0;
}

static OSStatus inputCallBackFun(    void *                            inRefCon,
                    AudioUnitRenderActionFlags *    ioActionFlags,
                    const AudioTimeStamp *            inTimeStamp,
                    UInt32                            inBusNumber,
                    UInt32                            inNumberFrames,
                    AudioBufferList * __nullable    ioData)
{

    if(m_isRecording == 0)
    {
        return noErr;
    }
    XBAudioUnitRecorder *recorder = (__bridge XBAudioUnitRecorder *)(inRefCon);
    typeof(recorder) __weak weakRecorder = recorder;
    
    [weakRecorder.m_lock_recode lock];
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = 0;
    
    OSStatus status = AudioUnitRender(recorder->audioUnit,
                    ioActionFlags,
                    inTimeStamp,
                    kInputBus,
                    inNumberFrames,
                    &bufferList);
    
    if(!status)
    {
        if (recorder.bl_output)
        {
            recorder.bl_output(&bufferList);
        }
        if (recorder.bl_outputFull)
        {
            recorder.bl_outputFull(weakRecorder, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
        }
    }

    [weakRecorder.m_lock_recode unlock];
    
    return noErr;
}
- (void)delete
{
    NSString *pcmPath = stroePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:pcmPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:pcmPath error:nil];
    }
}
@end
