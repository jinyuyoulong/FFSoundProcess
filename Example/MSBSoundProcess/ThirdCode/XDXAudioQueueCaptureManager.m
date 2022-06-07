//
//  XDXAudioQueueCaptureManager.m
//  XDXAudioQueueRecordAndPlayback
//
//  Created by 小东邪 on 2019/5/3.
//  Copyright © 2019 小东邪. All rights reserved.
//

#import "XDXAudioQueueCaptureManager.h"
#import "XDXAudioFileHandler.h"
#import <AVFoundation/AVFoundation.h>
#import <MSBSoundProcess/MSBAudioManager.h>
#import <MSBSoundProcessHeader.h>

#define kXDXAudioPCMFramesPerPacket 1
#define kXDXAudioPCMBitsPerChannel  16
#define kChannelCount 1
#define kSampleRate 44100
#define kBufferSize 1024

static const int kNumberBuffers = 3;

struct XDXRecorderInfo {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[kNumberBuffers];
};
typedef struct XDXRecorderInfo *XDXRecorderInfoType;

static XDXRecorderInfoType m_audioInfo;

@interface XDXAudioQueueCaptureManager ()

@property (nonatomic, assign, readwrite) BOOL isRunning;
@property (nonatomic, strong)MSBAudioManager *audioManager;
@property (nonatomic, strong) NSMutableData * audioData;

@end

@implementation XDXAudioQueueCaptureManager
SingletonM

#pragma mark - Callback
static void CaptureAudioDataCallback(void *                                 inUserData,
                                     AudioQueueRef                          inAQ,
                                     AudioQueueBufferRef                    inBuffer,
                                     const AudioTimeStamp *                 inStartTime,
                                     UInt32                                 inNumPackets,
                                     const AudioStreamPacketDescription*    inPacketDesc) {
    
    XDXAudioQueueCaptureManager *instance = (__bridge XDXAudioQueueCaptureManager *)inUserData;
    
    /*  Test audio fps
    static Float64 lastTime = 0;
    Float64 currentTime = CMTimeGetSeconds(CMClockMakeHostTimeFromSystemUnits(inStartTime->mHostTime))*1000;
    NSLog(@"Test duration - %f",currentTime - lastTime);
    lastTime = currentTime;
    */
    
//      Test size
//    if (inPacketDesc) {
//        NSLog(@"Test data: %d,%d,%d,%d",inBuffer->mAudioDataByteSize,inNumPackets,inPacketDesc->mDataByteSize,inPacketDesc->mVariableFramesInPacket);
//    }else {
//        NSLog(@"Test data: %u,%u",(unsigned int)inBuffer->mAudioDataByteSize,(unsigned int)inNumPackets);
//    }
//    
//    NSLog(@"inbuffer data: %u,%u",(unsigned int)inBuffer->mAudioDataByteSize,(unsigned int)inNumPackets);
    if (instance.isRecordVoice) {
        UInt32 bytesPerPacket = m_audioInfo->mDataFormat.mBytesPerPacket;
        if (inNumPackets == 0 && bytesPerPacket != 0) {
            inNumPackets = inBuffer->mAudioDataByteSize / bytesPerPacket;
        }
        
//        NSLog(@"inbuffer data: %u,%u",(unsigned int)inBuffer->mAudioDataByteSize,(unsigned int)inNumPackets);
        
//        [[XDXAudioFileHandler getInstance] writeFileWithInNumBytes:inBuffer->mAudioDataByteSize
//                                                      ioNumPackets:inNumPackets
//                                                          inBuffer:inBuffer->mAudioData
//                                                      inPacketDesc:inPacketDesc];
        [instance processAudioBuffer:inBuffer
                           withQueue:inAQ
                        inNumPackets:inNumPackets
                        inPacketDesc:inPacketDesc];
        
//        [instance processAudioBuffer:inBuffer
//                           withQueue:inAQ
//                        inNumPackets: m_audioInfo->mDataFormat.mBytesPerPacket
//                        inPacketDesc:inPacketDesc];
    }
    
    // 非录制检测
//    [instance processAudioBuffer:inBuffer
//                       withQueue:inAQ
//                    inNumPackets: m_audioInfo->mDataFormat.mBytesPerPacket
//                    inPacketDesc:inPacketDesc];
    if (instance.isRunning) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}
- (void)processAudioBuffer:(AudioQueueBufferRef )inBuffer
                 withQueue:(AudioQueueRef )audioQueueRef
              inNumPackets:(UInt32) inNumPackets
              inPacketDesc:(const AudioStreamPacketDescription *)inPacketDesc
{
    NSMutableData * dataM = [NSMutableData dataWithBytes:inBuffer->mAudioData
                                                  length:inBuffer->mAudioDataByteSize];

    
//    if (dataM.length < 960) { //处理长度小于960的情况,此处是补00
//        Byte byte[] = {0x00};
//        NSData * zeroData = [[NSData alloc] initWithBytes:byte length:1];
//        for (NSUInteger i = dataM.length; i < 960; i++) {
//            [dataM appendData:zeroData];
//        }
//    }
//    NSMutableData *outputdata =  [[NSMutableData alloc]initWithData:[self.audioManager preProcess:dataM]];
    
//    NSArray<MSBVoiceVadInfo *> *result =  [self.audioManager vadProcess:dataM];
//    for (MSBVoiceVadInfo *info in result) {
//        NSLog(@"实时录音的数据 Vad： --time: %d vocal: %d", info.timeMs,info.vocal);
//    }
//
    //base64编码数据
//    NSString *dataStr = [[NSString alloc] initWithData:dataM encoding:NSUTF8StringEncoding];
    
//    NSString *base64Str = [dataM base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
////    NSLog(@"实时录音的数据 Pitch ： -- pitch string:%@",dataStr);
//    char * cStr = [base64Str cStringUsingEncoding:kCFStringEncodingUTF8];
//    char * x = (char *)malloc(strlen([base64Str UTF8String]) + 1);
//    strcpy(x, [base64Str UTF8String]);
//    voicePitchProcess(x);
    
    
    
//    float *longdata;
//    float *longtemp;
//    int longnum = (int)[dataM length]/sizeof(float);
//    longdata = (float*)[dataM bytes];
//    NSMutableArray *tempArray = [NSMutableArray array];
//    for(int i=0; i<longnum; i++) {
//
//        longtemp = longdata + i;
//        NSLog(@"longtemp = %f", *longtemp);
//        NSString * longStr = [NSString stringWithFormat:@"%f",*longtemp];
//        [tempArray addObject:longStr];
//
//    }
    
//    NSUInteger len = [dataM length];
//    Byte *byteData = (Byte*)malloc(len);
//    memcpy(byteData, [dataM bytes], len);

    // Byte数组转int32类型
//    Byte byte[] = {0x47,0x33,0x18,0x00};//{0x00,0x18,0x33,0x47};
//    NSData*subdata = [dataM subdataWithRange:NSMakeRange(0, 4)];
//    Byte *subbytes = (Byte*)[subdata bytes];
//    NSData * data = [NSData dataWithBytes:byte length:sizeof(byte)];
//    int32_t bytes;
//    [data getBytes:&bytes length:sizeof(bytes)];
//    bytes = OSSwapBigToHostInt32(bytes);
//    NSLog(@"bytes=%d",inBuffer->mAudioData);
//    float number;
//    memcpy(&number, &bytes, sizeof(bytes));
//    NSLog(@"bytes=%f",number);
    
//    [self convertDataToLongArrayWithData:dataM];
    
//    for (int i=0; i<inBuffer->mAudioDataByteSize; i++) {
//        Byte byte = inBuffer->mAudioData[i];
//        NSLog(@"bytes=%f",inBuffer->mAudioData);
//    }
//    NSLog(@"bytes=%f",inBuffer->mAudioData);
//    NSArray<MSBVoicePitchInfo *> *pitchresult =  [[MSBAudioManager share] pitchProcess:dataM];
//    if (pitchresult.count > 0) {
//        NSLog(@"实时录音的数据 Pitch ： -- pitch:%f", pitchresult.lastObject.freq);
//    }
    
    
//    for (MSBVoicePitchInfo *info in pitchresult) {
//        NSLog(@"实时录音的数据 Pitch ： -- pitch:%f", info.freq);
//    }
//    
//    NSArray<MSBVoiceNoteInfo *> *noteresult =  [self.audioManager noteProcess:dataM];
//
//    for (MSBVoiceNoteInfo *info in noteresult) {
//        NSLog(@"实时录音的数据 Note： --note:%f", info.note);
//    }
    
    
//    [self.audioData appendData:outputdata];

    //    1024byte -> 882byte
//    NSLog(@"实时录音的数据--%@", outputdata);
//    AudioQueueBufferRef minbuffer = {
//        inBuffer->mAudioDataBytesCapacity,
//        outputdata,
//        (UInt32)[outputdata length],
//        inBuffer->mUserData,
//        inBuffer->mPacketDescriptionCapacity,
//        inBuffer->mPacketDescriptions,
//        inBuffer->mPacketDescriptionCount
//    };
//    NSLog(@"实时录音的数据--%u", (unsigned int)minbuffer->mAudioDataByteSize);
    
//    [[XDXAudioFileHandler getInstance] writeFileWithInNumBytes:inBuffer->mAudioDataByteSize
//                                                  ioNumPackets:inNumPackets
//                                                      inBuffer:inBuffer->mAudioData
//                                                  inPacketDesc:inPacketDesc];
//    [[XDXAudioFileHandler getInstance] writeFileWithData:outputdata];
//    [self.audioData appendData:dataM];
    [[XDXAudioFileHandler getInstance] writeFileWithData:dataM];
//
//    [[XDXAudioFileHandler getInstance] writeFileWithInNumBytes:(UInt32)[outputdata length]
//                                                  ioNumPackets:inNumPackets
//                                                      inBuffer:(__bridge const void * _Nonnull)(outputdata)
//                                                  inPacketDesc:inPacketDesc];
}
- (void)floatArrayData:(NSData*)dataM {
    NSMutableString *logStr = [[NSMutableString alloc] initWithCapacity:0];
    for(int i = 0, count = 1024; i < count; i+=4 ){
        Byte *byte1 = (Byte*)[[dataM subdataWithRange:NSMakeRange(i, 1)] bytes];
        Byte *byte2 = (Byte*)[[dataM subdataWithRange:NSMakeRange(i + 1, 1)] bytes];
        Byte *byte3 = (Byte*)[[dataM subdataWithRange:NSMakeRange(i + 2, 1)] bytes];
        Byte *byte4= (Byte*)[[dataM subdataWithRange:NSMakeRange(i + 3, 1)] bytes];
        Byte mbytes[] = {byte1,byte2,byte3,byte4};
        NSData *data = [NSData dataWithBytes:mbytes length:sizeof(mbytes)];
        
        int32_t bytes;
        bytes = OSSwapBigToHostInt32(bytes);
        float number;
        memcpy(&number, &bytes, sizeof(bytes));
        [logStr appendString:[NSString stringWithFormat:@"%f;",number]];
        
//        int count = 4;
//    //    int count = bytes[[dataM length] -1];
//        Byte *bytedata = (Byte*)malloc(count);
//        memcpy(bytedata, bytes, count);
//        NSLog(@"bytes=%s",bytedata);
//        free(bytedata);
    }
    NSLog(@"bytes=%@",logStr);
}
-(NSArray *) convertDataToLongArrayWithData:(NSData *)data{

    long *longdata;
    long *longtemp;
    int longnum = (int)[data length]/sizeof(long);
    longdata = (long*)[data bytes];
    NSMutableArray *tempArray = [NSMutableArray array];
    for(int i=0; i<longnum; i++) {

        longtemp = longdata + i;
        NSLog(@"longtemp = %ld", *longtemp);
        NSString * longStr = [NSString stringWithFormat:@"%ld",*longtemp];
        [tempArray addObject:longStr];
        
    }
    return tempArray;
}
#pragma mark - Init
+ (void)initialize {
    m_audioInfo = malloc(sizeof(struct XDXRecorderInfo));
}

- (instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [super init];
        _audioData = [[NSMutableData alloc] init];
        // Note: audioBufferSize不能超过durationSec最大大小。
        [self configureAudioCaptureWithAudioInfo:m_audioInfo
                                        formatID:kAudioFormatLinearPCM
//                                        formatID:kAudioFormatMPEG4AAC
                                      sampleRate:kSampleRate
                                    channelCount:kChannelCount
                                     durationSec:0.05
                                      bufferSize:kBufferSize
                                       isRunning:&self->_isRunning];
    });
    return _instace;
}

+ (instancetype)getInstance {    
    return [[self alloc] init];
}
#pragma mark - lazy
//- (MSBAudioManager *)audioManager
//{
//    if(!_audioManager)
//    {
//        _audioManager = [MSBAudioManager share];// [[MSBAudioManager alloc] initWithSampleRate:kSampleRate channel:kChannelCount];
//    }
//    return _audioManager;
//}

-(AudioStreamBasicDescription)getAudioFormatWithFormatID:(UInt32)formatID
                                              sampleRate:(Float64)sampleRate
                                            channelCount:(UInt32)channelCount {
    AudioStreamBasicDescription dataFormat = {0};
    
    UInt32 size = sizeof(dataFormat.mSampleRate);
    // Get hardware origin sample rate. (Recommended it)
    Float64 hardwareSampleRate = 0;
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
                            &size,
                            &hardwareSampleRate);
    // Manual set sample rate
    dataFormat.mSampleRate = sampleRate;
    
    size = sizeof(dataFormat.mChannelsPerFrame);
    // Get hardware origin channels number. (Must refer to it)
    UInt32 hardwareNumberChannels = 0;
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels,
                            &size,
                            &hardwareNumberChannels);
    dataFormat.mChannelsPerFrame = channelCount;
    
    // Set audio format
    dataFormat.mFormatID = formatID;
    
    // Set detail audio format params
    if (formatID == kAudioFormatLinearPCM) {
        dataFormat.mFormatFlags     = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        dataFormat.mBitsPerChannel  = kXDXAudioPCMBitsPerChannel;
        dataFormat.mBytesPerPacket  = dataFormat.mBytesPerFrame = (dataFormat.mBitsPerChannel / 8) * dataFormat.mChannelsPerFrame;
        dataFormat.mFramesPerPacket = kXDXAudioPCMFramesPerPacket;
    }else if (formatID == kAudioFormatMPEG4AAC) {
        dataFormat.mFormatFlags = kMPEG4Object_AAC_Main;
    }

    NSLog(@"Audio Recorder: starup PCM audio encoder:%f,%d",sampleRate,channelCount);
    return dataFormat;
}

#pragma mark - Public
- (void)startAudioCapture {
    [self startAudioCaptureWithAudioInfo:m_audioInfo
                               isRunning:&_isRunning];
}

- (void)pauseAudioCapture {
    [self pauseAudioCaptureWithAudioInfo:m_audioInfo
                               isRunning:&_isRunning];
}

- (void)stopAudioCapture {
    [self stopAudioQueueRecorderWithAudioInfo:m_audioInfo
                                    isRunning:&_isRunning];
}

- (void)freeAudioCapture {
    [self freeAudioQueueRecorderWithAudioInfo:m_audioInfo
                                    isRunning:&_isRunning];
}

- (void)startRecordFile {
    BOOL isNeedMagicCookie = NO;
    // 注意: 未压缩数据不需要PCM,可根据需求自行添加
    if (m_audioInfo->mDataFormat.mFormatID == kAudioFormatLinearPCM) {
//        isNeedMagicCookie = NO;
        isNeedMagicCookie = YES;
    }else {
        isNeedMagicCookie = YES;
    }
    [[XDXAudioFileHandler getInstance] startVoiceRecordByAudioQueue:m_audioInfo->mQueue
                                                  isNeedMagicCookie:isNeedMagicCookie
                                                          audioDesc:m_audioInfo->mDataFormat];
    self.isRecordVoice = YES;
    NSLog(@"Audio Recorder: Start record file.");
}

- (void)stopRecordFile {
    self.isRecordVoice = NO;
    BOOL isNeedMagicCookie = NO;
    if (m_audioInfo->mDataFormat.mFormatID == kAudioFormatLinearPCM) {
//        isNeedMagicCookie = NO;
        isNeedMagicCookie = YES;
    }else {
        isNeedMagicCookie = YES;
    }
    
//    [[XDXAudioFileHandler getInstance] writeFileWithData:self.audioData];
//    [[XDXAudioFileHandler getInstance]  stopWriteToFile];
    
    [[XDXAudioFileHandler getInstance] stopVoiceRecordByAudioQueue:m_audioInfo->mQueue
                                                   needMagicCookie:isNeedMagicCookie];
    NSLog(@"Audio Recorder: Stop record file.");
}
- (void)startProcessVoice {
//    [MSBAudioManager share].processStatus = 1;
    
}
- (void)stopProcessVoice {
    [MSBUnityAudioCaptureInterface.shared stopVoiceProcess];
//    stopVoiceProcess();
}
#pragma mark - Private
- (void)configureAudioCaptureWithAudioInfo:(XDXRecorderInfoType)audioInfo
                                  formatID:(UInt32)formatID
                                sampleRate:(Float64)sampleRate
                              channelCount:(UInt32)channelCount
                               durationSec:(float)durationSec
                                bufferSize:(UInt32)bufferSize
                                 isRunning:(BOOL *)isRunning {
    // Get Audio format ASBD
    audioInfo->mDataFormat = [self getAudioFormatWithFormatID:formatID
                                                   sampleRate:sampleRate
                                                 channelCount:channelCount];
    
    // Set sample time
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:durationSec error:NULL];
    
    // New queue
    OSStatus status = AudioQueueNewInput(&audioInfo->mDataFormat,
                                         CaptureAudioDataCallback,
                                         (__bridge void *)(self),
                                         NULL,
                                         kCFRunLoopCommonModes,
                                         0,
                                         &audioInfo->mQueue);
    
    if (status != noErr) {
        NSLog(@"Audio Recorder: audio queue new input failed status:%d \n",(int)status);
    }
    
    // Set audio format for audio queue
    UInt32 size = sizeof(audioInfo->mDataFormat);
    status = AudioQueueGetProperty(audioInfo->mQueue,
                                   kAudioQueueProperty_StreamDescription,
                                   &audioInfo->mDataFormat,
                                   &size);
    if (status != noErr) {
        NSLog(@"Audio Recorder: get ASBD status:%d",(int)status);
    }
    
    // Set capture data size
    UInt32 maxBufferByteSize;
    if (audioInfo->mDataFormat.mFormatID == kAudioFormatLinearPCM) {
        int frames = (int)ceil(durationSec * audioInfo->mDataFormat.mSampleRate);
        maxBufferByteSize = frames*audioInfo->mDataFormat.mBytesPerFrame*audioInfo->mDataFormat.mChannelsPerFrame;
    }else {
        // AAC durationSec MIN: 23.219708 ms
        maxBufferByteSize = durationSec * audioInfo->mDataFormat.mSampleRate;
        
        if (maxBufferByteSize < kBufferSize) {
            maxBufferByteSize = kBufferSize;
        }
    }
    
    if (bufferSize > maxBufferByteSize || bufferSize == 0) {
        bufferSize = maxBufferByteSize;
    }
    
    // Allocate and Enqueue
    for (int i = 0; i != kNumberBuffers; i++) {
        status = AudioQueueAllocateBuffer(audioInfo->mQueue,
                                          bufferSize,
                                          &audioInfo->mBuffers[i]);
        if (status != noErr) {
            NSLog(@"Audio Recorder: Allocate buffer status:%d",(int)status);
        }
        
        status = AudioQueueEnqueueBuffer(audioInfo->mQueue,
                                         audioInfo->mBuffers[i],
                                         0,
                                         NULL);
        if (status != noErr) {
            NSLog(@"Audio Recorder: Enqueue buffer status:%d",(int)status);
        }
    }
}

- (BOOL)startAudioCaptureWithAudioInfo:(XDXRecorderInfoType)audioInfo isRunning:(BOOL *)isRunning {
    if (*isRunning) {
        NSLog(@"Audio Recorder: Start recorder repeat");
        return NO;
    }
    
    OSStatus status = AudioQueueStart(audioInfo->mQueue, NULL);
    if (status != noErr) {
        NSLog(@"Audio Recorder: Audio Queue Start failed status:%d \n",(int)status);
        return NO;
    }else {
        NSLog(@"Audio Recorder: Audio Queue Start successful");
        *isRunning = YES;
        return YES;
    }
}
- (BOOL)pauseAudioCaptureWithAudioInfo:(XDXRecorderInfoType)audioInfo isRunning:(BOOL *)isRunning {
    if (!*isRunning) {
        NSLog(@"Audio Recorder: audio capture is not running !");
        return NO;
    }
    
    OSStatus status = AudioQueuePause(audioInfo->mQueue);
    if (status != noErr) {
        NSLog(@"Audio Recorder: Audio Queue pause failed status:%d \n",(int)status);
        return NO;
    }else {
        NSLog(@"Audio Recorder: Audio Queue pause successful");
        *isRunning = NO;
        return YES;
    }
}

-(BOOL)stopAudioQueueRecorderWithAudioInfo:(XDXRecorderInfoType)audioInfo isRunning:(BOOL *)isRunning {
    if (*isRunning == NO) {
        NSLog(@"Audio Recorder: Stop recorder repeat \n");
        return NO;
    }
    
    if (audioInfo->mQueue) {
        OSStatus stopRes = AudioQueueStop(audioInfo->mQueue, true);
        
        if (stopRes == noErr){
            NSLog(@"Audio Recorder: stop Audio Queue success.");
            return YES;
        }else{
            NSLog(@"Audio Recorder: stop Audio Queue failed.");
            return NO;
        }
    }else {
        NSLog(@"Audio Recorder: stop Audio Queue failed, the queue is nil.");
        return NO;
    }
}

-(BOOL)freeAudioQueueRecorderWithAudioInfo:(XDXRecorderInfoType)audioInfo isRunning:(BOOL *)isRunning {
    if (*isRunning) {
        [self stopAudioQueueRecorderWithAudioInfo:audioInfo isRunning:isRunning];
    }
    
    if (audioInfo->mQueue) {
        for (int i = 0; i < kNumberBuffers; i++) {
            AudioQueueFreeBuffer(audioInfo->mQueue, audioInfo->mBuffers[i]);
        }
        
        OSStatus status = AudioQueueDispose(audioInfo->mQueue, true);
        if (status != noErr) {
            NSLog(@"Audio Recorder: Dispose failed: %d",status);
        }else {
            audioInfo->mQueue = NULL;
            *isRunning = NO;
            NSLog(@"Audio Recorder: free AudioQueue successful.");
            return YES;
        }
    }else {
        NSLog(@"Audio Recorder: free Audio Queue failed, the queue is nil.");
    }
    
    return NO;
}


#pragma mark Other
-(int)computeRecordBufferSizeFrom:(const AudioStreamBasicDescription *)format
                       audioQueue:(AudioQueueRef)audioQueue
                      durationSec:(float)durationSec {
    int packets = 0;
    int frames  = 0;
    int bytes   = 0;
    
    frames = (int)ceil(durationSec * format->mSampleRate);
    
    if (format->mBytesPerFrame > 0)
        bytes = frames * format->mBytesPerFrame;
    else {
        UInt32 maxPacketSize;
        if (format->mBytesPerPacket > 0){   // CBR
            maxPacketSize = format->mBytesPerPacket;    // constant packet size
        }else { // VBR
            // AAC Format get kAudioQueueProperty_MaximumOutputPacketSize return -50. so the method is not effective.
            UInt32 propertySize = sizeof(maxPacketSize);
            OSStatus status     = AudioQueueGetProperty(audioQueue,
                                                        kAudioQueueProperty_MaximumOutputPacketSize,
                                                        &maxPacketSize,
                                                        &propertySize);
            if (status != noErr) {
                NSLog(@"%s: get max output packet size failed:%d",__func__,status);
            }
        }
        
        if (format->mFramesPerPacket > 0)
            packets = frames / format->mFramesPerPacket;
        else
            packets = frames;    // worst-case scenario: 1 frame in a packet
        if (packets == 0)        // sanity check
            packets = 1;
        bytes = packets * maxPacketSize;
    }
    
    return bytes;
}

- (void)printASBD:(AudioStreamBasicDescription)asbd {
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10X",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10d",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10d",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10d",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10d",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10d",    asbd.mBitsPerChannel);
}

- (void)dealloc {
    free(m_audioInfo);
}
@end
