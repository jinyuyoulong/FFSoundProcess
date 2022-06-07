//
//  XBAudioPlayAndRecoder.m
//  SoundProcessIosDemo
//
//  Created by 朱韦刚 on 2021/8/19.
//

#import "XBAudioPlayAndRecoder.h"
#import "XBAudioTool.h"

#define subPathPCM @"/Documents/xbMedia"
#define stroePath [NSHomeDirectory() stringByAppendingString:subPathPCM]

@interface XBAudioUnitPlayAndRecorder ()
{
    AudioUnit audioUnit_recoder;
    AudioUnit audioUnit_player;
}
@property (nonatomic,assign) XBAudioBit bit;
@property (nonatomic,assign) XBAudioRate rate;
@property (nonatomic,assign) XBAudioChannel channel;
@property (nonatomic,assign) AudioStreamBasicDescription inputStreamDesc;
@end

@implementation XBAudioUnitPlayAndRecorder

- (instancetype)initWithRate_palyandrecode:(NSString *)playfilePath rate:(XBAudioRate)rate bit:(XBAudioBit)bit channel:(XBAudioChannel)channel
{
    if (self = [super init])
    {
        self.filePath = playfilePath;
        self.bit = bit;
        self.rate = rate;
        self.channel = channel;
        
        self.dataStore = [NSData dataWithContentsOfFile:self.filePath];
        self.reader = [XBAudioPCMDataReader new];
        
        [self initInputAudioUnitWithRate:self.rate bit:self.bit channel:self.channel];
    }
    return self;
}

-(int)getinputLatency
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    NSTimeInterval ioduration = [session inputLatency];
    return  (int)(ioduration *1000);
}

- (void)initInputAudioUnitWithRate:(XBAudioRate)rate bit:(XBAudioBit)bit channel:(XBAudioChannel)channel
{
    //设置AVAudioSession
//    NSError *error = nil;
//    AVAudioSession* session = [AVAudioSession sharedInstance];
//
//    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
//    //[session setPreferredIOBufferDuration:0.04 error:&error]; //设置缓冲区40毫秒,没用;
//    [session setActive:YES error:nil];

    
    //recoder;
    //初始化audioUnit
    AudioComponentDescription inputDesc = [XBAudioTool allocAudioComponentDescriptionWithComponentType:kAudioUnitType_Output componentSubType:kAudioUnitSubType_RemoteIO componentFlags:0 componentFlagsMask:0];
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &inputDesc);
    CheckError(AudioComponentInstanceNew(inputComponent, &audioUnit_recoder), "AudioComponentInstanceNew failure");
    

    //设置输出流格式
    int mFramesPerPacket = 1;
    AudioStreamBasicDescription inputStreamDesc = [XBAudioTool allocAudioStreamBasicDescriptionWithMFormatID:kAudioFormatLinearPCM mFormatFlags:(kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsPacked) mSampleRate:rate mFramesPerPacket:mFramesPerPacket mChannelsPerFrame:channel mBitsPerChannel:bit];
    self.inputStreamDesc = inputStreamDesc;
    
    OSStatus status = AudioUnitSetProperty(audioUnit_recoder,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         kInputBus,
                         &inputStreamDesc,
                         sizeof(inputStreamDesc));
    CheckError(status, "setProperty inputStreamFormat error");
    
    //麦克风输入设置为1（yes）
    int inputEnable = 1;
    status = AudioUnitSetProperty(audioUnit_recoder,
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
    
    status = AudioUnitSetProperty(audioUnit_recoder,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &inputCallBackStruce,
                                  sizeof(inputCallBackStruce));
    CheckError(status, "setProperty InputCallback error");
    
    AudioStreamBasicDescription outputDesc0;
    UInt32 size = sizeof(outputDesc0);
    CheckError(AudioUnitGetProperty(audioUnit_recoder,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &outputDesc0,
                                    &size),"get property failure");
    
    AudioStreamBasicDescription outputDesc1;
    size = sizeof(outputDesc1);
    CheckError(AudioUnitGetProperty(audioUnit_recoder,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &outputDesc1,
                                    &size),"get property failure");
    
    //player;
    //初始化audioUnit
    //kAudioUnitSubType_RemoteIO 能调节到最小音量按键能用;
    //kAudioUnitSubType_VoiceProcessingIO 不能调节到最小音量键不能用;
    AudioComponentDescription outputDesc = [XBAudioTool allocAudioComponentDescriptionWithComponentType:kAudioUnitType_Output
                                                                                       componentSubType:kAudioUnitSubType_RemoteIO
                                                                                         componentFlags:0
                                                                                     componentFlagsMask:0];
    AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputDesc);
    AudioComponentInstanceNew(outputComponent, &audioUnit_player);
    
    
    
    //设置输出格式
    mFramesPerPacket = 1;
    AudioStreamBasicDescription streamDesc = [XBAudioTool allocAudioStreamBasicDescriptionWithMFormatID:kAudioFormatLinearPCM
                                                                                           mFormatFlags:(kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved)
                                                                                            mSampleRate:rate
                                                                                       mFramesPerPacket:mFramesPerPacket
                                                                                      mChannelsPerFrame:channel
                                                                                        mBitsPerChannel:bit];
    
    status = AudioUnitSetProperty(audioUnit_player,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &streamDesc,
                                  sizeof(streamDesc));
    CheckError(status, "SetProperty StreamFormat failure");
    
    //设置回调
    AURenderCallbackStruct outputCallBackStruct;
    outputCallBackStruct.inputProc = outputCallBackFun;
    outputCallBackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit_player,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &outputCallBackStruct,
                                  sizeof(outputCallBackStruct));
    CheckError(status, "SetProperty EnableIO failure");
}

- (void)start
{
    [self delete];
    AudioOutputUnitStart(audioUnit_recoder);
    _isRecording = YES;
    AudioOutputUnitStart(audioUnit_player);
    _isPlaying = YES;
}

- (void)stop
{
    AudioUnitReset(audioUnit_recoder, kAudioUnitScope_Global, 0);
    CheckError(AudioOutputUnitStop(audioUnit_recoder),
               "AudioOutputUnitStop failed");
    _isRecording = NO;
    AudioUnitReset(audioUnit_player, kAudioUnitScope_Global, 0);
    AudioOutputUnitStop(audioUnit_player);
    _isPlaying = NO;
    
//    NSError *error = nil;
//    AVAudioSession* session = [AVAudioSession sharedInstance];
//    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
//    [session setActive:NO error:nil];
}

- (void)dealloc
{
    CheckError(AudioComponentInstanceDispose(audioUnit_recoder),
               "AudioComponentInstanceDispose failed");
    NSLog(@"XBAudioUnitRecorder销毁");
    
    CheckError(AudioComponentInstanceDispose(audioUnit_player),
               "AudioComponentInstanceDispose failed");
    NSLog(@"audioUnit_player销毁");
}

- (void)delete
{
    NSString *pcmPath = stroePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:pcmPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:pcmPath error:nil];
    }
}


//recoder回调;
static OSStatus inputCallBackFun(    void *                            inRefCon,
                    AudioUnitRenderActionFlags *    ioActionFlags,
                    const AudioTimeStamp *            inTimeStamp,
                    UInt32                            inBusNumber,
                    UInt32                            inNumberFrames,
                    AudioBufferList * __nullable    ioData)
{

    XBAudioUnitPlayAndRecorder *recorder = (__bridge XBAudioUnitPlayAndRecorder *)(inRefCon);
    typeof(recorder) __weak weakRecorder = recorder;
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = 0;
    
    AudioUnitRender(recorder->audioUnit_recoder,
                    ioActionFlags,
                    inTimeStamp,
                    kInputBus,
                    inNumberFrames,
                    &bufferList);
    
    if (recorder.bl_output)
    {
        recorder.bl_output(&bufferList);
    }
    if (recorder.bl_outputFull)
    {
        recorder.bl_outputFull(weakRecorder, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    }
    
    return noErr;
}

//player回调;
static OSStatus outputCallBackFun(void *                            inRefCon,
                                  AudioUnitRenderActionFlags *    ioActionFlags,
                                  const AudioTimeStamp *            inTimeStamp,
                                  UInt32                            inBusNumber,
                                  UInt32                            inNumberFrames,
                                  AudioBufferList * __nullable    ioData)
{
    //NSLog(@"yanchi end1 play");
    memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
    //    memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
    
    XBAudioUnitPlayAndRecorder *player = (__bridge XBAudioUnitPlayAndRecorder *)(inRefCon);
    typeof(player) __weak weakPlayer = player;
    if (player.bl_input)
    {
        player.bl_input(ioData);
    }
    if (player.bl_inputFull)
    {
        //从文件中读取数据;
        AudioBuffer buffer = ioData->mBuffers[0];
        int len = buffer.mDataByteSize;
        int readLen = [player.reader readDataFrom:player.dataStore len:len forData:buffer.mData];
        buffer.mDataByteSize = readLen;
        
        player.bl_inputFull(weakPlayer, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    }
    return noErr;
}

@end


