//
//  MSBAudioUnitGraph.m
//  MSBMediaModule
//
//  Created by 李响 on 2021/4/6.
//

#import "MSBAudioUnitGraph.h"
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>


#define kInputBus 1     // IO Unit Element 1
#define kOutputBus 0    // IO Unit Element 0

FILE *file = NULL;
@interface MSBAudioUnitGraph ()

@end

@implementation MSBAudioUnitGraph {
    AUGraph auGraph;
    AudioUnit remoteIOUnit;
    AUNode remoteIONode;
    AURenderCallbackStruct inputProc;
}

#pragma mark - CallBack
static OSStatus inputCallBack(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber,UInt32 inNumberFrames,AudioBufferList *ioData){
    MSBAudioUnitGraph *unitGraph=(__bridge MSBAudioUnitGraph*)inRefCon;
    OSStatus renderErr = AudioUnitRender(unitGraph->remoteIOUnit,
                                         ioActionFlags,
                                         inTimeStamp,
                                         1,
                                         inNumberFrames,
                                         ioData);
    NSData *data = [NSData dataWithBytes:ioData->mBuffers->mData length:ioData->mBuffers->mDataByteSize];
    [unitGraph.delegate audioCaptureGetDataCallback:unitGraph audioData:data];
    if (unitGraph -> _filePath && unitGraph -> _filePath.length != 0) {
        [unitGraph writePCMData:ioData->mBuffers->mData size:ioData->mBuffers->mDataByteSize];
    }
    return renderErr;
}

#pragma mark Init
- (instancetype)init{
    self = [super init];
    if (self) {
        [self initAudioUnit];
    }
    return self;
}

#pragma mark Private API
- (void)initAudioUnit{
    [self setAudioSession];
    [self setNewAndOpenAUGraph];
    [self setAudioComponent];
    [self setAudioFormat];
    [self setInputCallBack];
    [self setAndUpdateAUGraph];
}


#pragma mark Public API
- (void)startaudioUnitRecordAndPlay {
    CheckError(AUGraphStart(auGraph),"不能 AUGraphStart");
    CAShow(auGraph);
}

- (void)stopAudioUnitStop {
    CheckError(AUGraphStop(auGraph), "不能 AUGraphStop");
}

- (void)writePCMData:(char *)buffer size:(int)size {
    if (!file) {
        file = fopen(self.filePath.UTF8String, "w");
    }
    fwrite(buffer, size, 1, file);
}

#pragma mark - 音频配置
///麦克风配置
- (void)setAudioSession API_AVAILABLE(ios(10.0), watchos(3.0), tvos(10.0)){
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
//    采用 A2DP 协议将 蓝牙设备作为音频输出设备。通常用来作为高质量音频蓝牙输出，比如播放音乐，此协议下蓝牙设备 无法作为音频输入设备，音频输入需要使用手机麦克风
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionAllowBluetoothA2DP
                        error:&error];
    [audioSession setPreferredIOBufferDuration:0.01 error:&error];
}

- (void)setNewAndOpenAUGraph {
    CheckError(NewAUGraph(&auGraph),"创建NewAUGraph失败...");
    CheckError(AUGraphOpen(auGraph),"打开NewAUGraph失败...");
}

- (void)setAudioComponent {
    AudioComponentDescription componentDesc;
    componentDesc.componentType = kAudioUnitType_Output;
    componentDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDesc.componentFlags = 0;
    componentDesc.componentFlagsMask = 0;
    
    CheckError (AUGraphAddNode(auGraph,&componentDesc,&remoteIONode),"不能添加remote io node");
    CheckError(AUGraphNodeInfo(auGraph,remoteIONode,NULL,&remoteIOUnit),"不能获取 remote io unit from node");
}

- (void)setAudioFormat {
    //set BUS
    UInt32 oneFlag = 1;
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    kOutputBus,
                                    &oneFlag,
                                    sizeof(oneFlag)),"不能 kAudioOutputUnitProperty_EnableIO with kAudioUnitScope_Output");

    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &oneFlag,
                                    sizeof(oneFlag)),"不能 kAudioOutputUnitProperty_EnableIO with kAudioUnitScope_Input");
    
    AudioStreamBasicDescription mAudioFormat;
    mAudioFormat.mSampleRate         = 44100.0;//采样率
    mAudioFormat.mFormatID           = kAudioFormatLinearPCM;//PCM采样
    mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mAudioFormat.mReserved           = 0;
    mAudioFormat.mChannelsPerFrame   = 1;//1单声道，2立体声，但是改为2也并不是立体声
    mAudioFormat.mBitsPerChannel     = 16;//语音每采样点占用位数
    mAudioFormat.mFramesPerPacket    = 1;//每个数据包多少帧
    mAudioFormat.mBytesPerFrame      = (mAudioFormat.mBitsPerChannel / 8) * mAudioFormat.mChannelsPerFrame; // 每帧的bytes数
    mAudioFormat.mBytesPerPacket     = mAudioFormat.mBytesPerFrame;//每个数据包的bytes总数，每帧的bytes数＊每个数据包的帧数
    
    UInt32 size = sizeof(mAudioFormat);
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &mAudioFormat,
                                    size),"不能设置kAudioUnitProperty_StreamFormat with kAudioUnitScope_Output");
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &mAudioFormat,
                                    size),"不能设置kAudioUnitProperty_StreamFormat with kAudioUnitScope_Input");
}

- (void)setInputCallBack {
    inputProc.inputProc = inputCallBack;
    inputProc.inputProcRefCon = (__bridge void *)(self);
    
    CheckError(AUGraphSetNodeInputCallback(auGraph, remoteIONode, 0, &inputProc),"Error setting io input callback");
}

- (void)setAndUpdateAUGraph {
    CheckError(AUGraphInitialize(auGraph),"不能AUGraphInitialize" );
    CheckError(AUGraphUpdate(auGraph, NULL),"不能AUGraphUpdate" );
}


#pragma mark Check Error
static void CheckError(OSStatus error, const char *operation){
    if (error == noErr) return;
    char str[20];
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
    sprintf(str, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
    exit(1);
}

@end
