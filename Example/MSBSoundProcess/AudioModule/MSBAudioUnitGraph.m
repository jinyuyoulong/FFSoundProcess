//
//  MSBAudioUnitGraph.m
//  MSBMediaModule
//
//  Created by ζε on 2021/4/6.
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
    CheckError(AUGraphStart(auGraph),"δΈθ½ AUGraphStart");
    CAShow(auGraph);
}

- (void)stopAudioUnitStop {
    CheckError(AUGraphStop(auGraph), "δΈθ½ AUGraphStop");
}

- (void)writePCMData:(char *)buffer size:(int)size {
    if (!file) {
        file = fopen(self.filePath.UTF8String, "w");
    }
    fwrite(buffer, size, 1, file);
}

#pragma mark - ι³ι’ιη½?
///ιΊ¦ει£ιη½?
- (void)setAudioSession API_AVAILABLE(ios(10.0), watchos(3.0), tvos(10.0)){
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
//    ιη¨ A2DP εθ??ε° θηθ?Ύε€δ½δΈΊι³ι’θΎεΊθ?Ύε€γιεΈΈη¨ζ₯δ½δΈΊι«θ΄¨ιι³ι’θηθΎεΊοΌζ―ε¦ζ­ζΎι³δΉοΌζ­€εθ??δΈθηθ?Ύε€ ζ ζ³δ½δΈΊι³ι’θΎε₯θ?Ύε€οΌι³ι’θΎε₯ιθ¦δ½Ώη¨ζζΊιΊ¦ει£
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionAllowBluetoothA2DP
                        error:&error];
    [audioSession setPreferredIOBufferDuration:0.01 error:&error];
}

- (void)setNewAndOpenAUGraph {
    CheckError(NewAUGraph(&auGraph),"εε»ΊNewAUGraphε€±θ΄₯...");
    CheckError(AUGraphOpen(auGraph),"ζεΌNewAUGraphε€±θ΄₯...");
}

- (void)setAudioComponent {
    AudioComponentDescription componentDesc;
    componentDesc.componentType = kAudioUnitType_Output;
    componentDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDesc.componentFlags = 0;
    componentDesc.componentFlagsMask = 0;
    
    CheckError (AUGraphAddNode(auGraph,&componentDesc,&remoteIONode),"δΈθ½ζ·»ε remote io node");
    CheckError(AUGraphNodeInfo(auGraph,remoteIONode,NULL,&remoteIOUnit),"δΈθ½θ·ε remote io unit from node");
}

- (void)setAudioFormat {
    //set BUS
    UInt32 oneFlag = 1;
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    kOutputBus,
                                    &oneFlag,
                                    sizeof(oneFlag)),"δΈθ½ kAudioOutputUnitProperty_EnableIO with kAudioUnitScope_Output");

    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &oneFlag,
                                    sizeof(oneFlag)),"δΈθ½ kAudioOutputUnitProperty_EnableIO with kAudioUnitScope_Input");
    
    AudioStreamBasicDescription mAudioFormat;
    mAudioFormat.mSampleRate         = 44100.0;//ιζ ·η
    mAudioFormat.mFormatID           = kAudioFormatLinearPCM;//PCMιζ ·
    mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mAudioFormat.mReserved           = 0;
    mAudioFormat.mChannelsPerFrame   = 1;//1εε£°ιοΌ2η«δ½ε£°οΌδ½ζ―ζΉδΈΊ2δΉεΉΆδΈζ―η«δ½ε£°
    mAudioFormat.mBitsPerChannel     = 16;//θ―­ι³ζ―ιζ ·ηΉε η¨δ½ζ°
    mAudioFormat.mFramesPerPacket    = 1;//ζ―δΈͺζ°ζ?εε€ε°εΈ§
    mAudioFormat.mBytesPerFrame      = (mAudioFormat.mBitsPerChannel / 8) * mAudioFormat.mChannelsPerFrame; // ζ―εΈ§ηbytesζ°
    mAudioFormat.mBytesPerPacket     = mAudioFormat.mBytesPerFrame;//ζ―δΈͺζ°ζ?εηbytesζ»ζ°οΌζ―εΈ§ηbytesζ°οΌζ―δΈͺζ°ζ?εηεΈ§ζ°
    
    UInt32 size = sizeof(mAudioFormat);
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &mAudioFormat,
                                    size),"δΈθ½θ?Ύη½?kAudioUnitProperty_StreamFormat with kAudioUnitScope_Output");
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &mAudioFormat,
                                    size),"δΈθ½θ?Ύη½?kAudioUnitProperty_StreamFormat with kAudioUnitScope_Input");
}

- (void)setInputCallBack {
    inputProc.inputProc = inputCallBack;
    inputProc.inputProcRefCon = (__bridge void *)(self);
    
    CheckError(AUGraphSetNodeInputCallback(auGraph, remoteIONode, 0, &inputProc),"Error setting io input callback");
}

- (void)setAndUpdateAUGraph {
    CheckError(AUGraphInitialize(auGraph),"δΈθ½AUGraphInitialize" );
    CheckError(AUGraphUpdate(auGraph, NULL),"δΈθ½AUGraphUpdate" );
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
