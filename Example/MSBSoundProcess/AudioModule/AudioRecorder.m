//
//  AudioRecorder.m
//  AudioQueueCaptureOC
//
//  Created by 范金龙 on 2021/1/16.
//  音频采集

#import "AudioRecorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "XDXAudioFileHandler.h"
#import "FFAudio.h"
#import "MSBAudioTools.h"

// AudioQueue 录音采集流程
//（1）首先，需要定义一些常数：
#define kNumberAudioQueueBuffers 1      // 输出音频队列缓冲个数,缓冲区个数
#define kDefaultBufferDurationSeconds 0.03//调整这个值使得录音的缓冲区大小为960,实际会小于或等于960,需要处理小于960的情况
#define kDefaultSampleRate 44100   //定义采样率为16000

extern NSString * const ESAIntercomNotifationRecordString;

@interface AudioRecorder ()
{
    AudioQueueRef _audioQueue;                          //输出音频播放队列
    AudioStreamBasicDescription _recordFormat;
    AudioQueueBufferRef _audioBuffers[kNumberAudioQueueBuffers]; //输出音频缓存
    AudioFileID m_recordFile;
    NSTimer *timer;
    BOOL recording;
}
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, copy) NSString *recordFilePath;
@property (nonatomic, assign)AudioComponentInstance componetInstance;
@property (nonatomic, assign)AudioComponent component;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong)FFAudio *audioQueuePlayer;
@end

@implementation AudioRecorder

+ (AudioRecorder*)defaultInstance {
    static AudioRecorder *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (shareInstance == nil) {
            shareInstance = [[AudioRecorder alloc] init];
        }
    });
    return  shareInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
        dispatch_sync(self.taskQueue, ^{
            if (self.componetInstance) {
                self.isRunning = NO;
                AudioOutputUnitStop(self.componetInstance);
                AudioComponentInstanceDispose(self.componetInstance);
                self.componetInstance = nil;
                self.component = nil;
            }
        });
}
- (void)initData {
    [self setupAudioForType1];
//    [self setupAudioForType2];
}
// 第一种录音方式
- (void)setupAudioForType1 {
    self.isRunning = NO;
    [self setupRecordFormat:kAudioFormatLinearPCM SampleRate:kDefaultSampleRate];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}
// 第二种录音方式
- (void)setupAudioForType2 {
    self.isRunning = NO;
    self.taskQueue = dispatch_queue_create("Jiangang.audioCapture.Queue", NULL);
    [self setupAudioFormat:kAudioFormatLinearPCM SampleRate:kDefaultSampleRate];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}
// MARK: - lazy
- (FFAudio *)audioQueuePlayer
{
    if(!_audioQueuePlayer)
    {
        _audioQueuePlayer = [[FFAudio alloc] init];
    }
    return _audioQueuePlayer;
}
- (void)setAudioSessionPort:(AVAudioSessionPort)audioSessionPort{
    _audioSessionPort = audioSessionPort;
    NSArray* availableInputs = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription *desc in availableInputs) {
        if ([desc.portType isEqualToString:audioSessionPort]) {
            NSError *error;
            [[AVAudioSession sharedInstance] setPreferredInput:desc error:&error];
        }
    }
}

//（2）接着，需要初始化录音的参数，在初始化时调用：
- (void)setupAudioFormat:(UInt32)inFormatID SampleRate:(int)sampeleRate {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: session];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: session];
    //初始化音频输入队列
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    acd.componentFlags = 0;
    acd.componentFlagsMask = 0;
    self.component = AudioComponentFindNext(NULL, &acd);
    OSStatus status = noErr;
    status = AudioComponentInstanceNew(self.component, &_componetInstance);
    if (noErr != status) {
        [self handleAudioComponentCreationFailure];
    }
    UInt32 flagOne = 1;
    //初始化音频输入队列
    AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
    
    AudioStreamBasicDescription desc = {0};
    desc.mSampleRate = sampeleRate;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    desc.mChannelsPerFrame = 1;
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = 16;
    desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    
    AURenderCallbackStruct cb;
    cb.inputProcRefCon = (__bridge void *)(self);
    cb.inputProc = handleInputBuffer;
    AudioUnitSetProperty(self.componetInstance, kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output, 1, &desc, sizeof(desc));
    AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global, 1, &cb, sizeof(cb));
    
    status = AudioUnitInitialize(self.componetInstance);
    
    if (noErr != status) {
        [self handleAudioComponentCreationFailure];
    }
            
    [session setPreferredSampleRate:sampeleRate error:nil];
    // 自定义设置，无耳机的话有回音
//    BOOL ret = [session setCategory:AVAudioSessionCategoryPlayAndRecord
//                        withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
//                              error:nil];
    // pod 内的设置，无耳机也没回音
    BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    if (!ret) {
        NSLog(@"设置声音环境失败！");
        return;
    }
    
    [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
    ret = [session setActive:YES error:&error];
    if (!ret) {
        NSLog(@"av audio session启动失败");
        return;
    }
    
    // blog方案的设置，taskQueue方案不用
    [self setupRecordFormat:inFormatID SampleRate:sampeleRate];
}
//（2）接着，需要初始化录音的参数，在初始化时调用：
- (void)setupRecordFormat:(UInt32)inFormatID SampleRate:(int)sampeleRate {
    //重置下 AudioStreamBasicDescription
    memset(&_recordFormat, 0, sizeof(_recordFormat));
//    _recordFormat = {0};
    //设置采样率，
    //采样率的意思是每秒需要采集的帧数
    _recordFormat.mSampleRate = sampeleRate; //kDefaultSampleRate;
    //设置通道数
    _recordFormat.mChannelsPerFrame = 1;
    _recordFormat.mFormatID = inFormatID;//kAudioFormatLinearPCM;

    if (inFormatID == kAudioFormatLinearPCM) {
        _recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
//        _recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger |  kLinearPCMFormatFlagIsPacked;
        //每个通道里，一帧采集的bit数目
        // 每个通道中的位数，1byte = 8bit
        _recordFormat.mBitsPerChannel = 16;
        //结果分析: 8bit为1byte，即为1个通道里1帧需要采集2byte数据，再*通道数，即为所有通道采集的byte数目。
        //所以这里结果赋值给每帧需要采集的byte数目，然后这里的packet也等于一帧的数据。
        //至于为什么要这样。。。不知道。。。
//        _recordFormat.mBytesPerFrame = _recordFormat.mBitsPerChannel / 8 * _recordFormat.mChannelsPerFrame;
        _recordFormat.mBytesPerPacket = _recordFormat.mBytesPerFrame * _recordFormat.mFramesPerPacket;

        _recordFormat.mBytesPerPacket = _recordFormat.mBytesPerFrame = (_recordFormat.mBitsPerChannel / 8) * _recordFormat.mChannelsPerFrame;
        _recordFormat.mFramesPerPacket = 1;
    }
}
//（3）设置好格式后，可以继续下一步，开始录制
- (void)startRecording {
//    [self setRunning: true];
    
    [self startRecording1];
}
-(void)startRecording1
{
    [[XDXAudioFileHandler getInstance] createFilePath];
    
    NSError *error = nil;
    
//    [[NSNotificationCenter defaultCenter] addObserver: self
//                                             selector: @selector(handleRouteChange:)
//                                                 name: AVAudioSessionRouteChangeNotification
//                                               object: session];
//    [[NSNotificationCenter defaultCenter] addObserver: self
//                                             selector: @selector(handleInterruption:)
//                                                 name: AVAudioSessionInterruptionNotification
//                                               object: session];
//    AudioComponentDescription acd;
//    acd.componentType = kAudioUnitType_Output;
//    acd.componentSubType = kAudioUnitSubType_RemoteIO;
//    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
//    acd.componentFlags = 0;
//    acd.componentFlagsMask = 0;
//    self.component = AudioComponentFindNext(NULL, &acd);
//    OSStatus status = noErr;
//    status = AudioComponentInstanceNew(self.component, &_componetInstance);
//    if (noErr != status) {
//        [self handleAudioComponentCreationFailure];
//    }
//
//    [session setPreferredSampleRate:kDefaultSampleRate error:nil];
//    BOOL ret = [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:nil];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL ret = [session setCategory:AVAudioSessionCategoryMultiRoute error:&error];
    if (!ret) {
        NSLog(@"设置声音环境失败！");
        return;
    }
    
    [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation
                 error:nil];
    
    ret = [session setActive:YES error:&error];
    if (!ret) {
        NSLog(@"启动失败");
        return;
    }
    _recordFormat.mSampleRate = kDefaultSampleRate;
    
    //初始化音频输入队列
    AudioQueueNewInput(&_recordFormat, inputBufferHandler, (__bridge void *)(self),
                       NULL, NULL, 0, &_audioQueue);

    //计算估算的缓存区大小
    int frames = (int)ceil(kDefaultBufferDurationSeconds * _recordFormat.mSampleRate);
    int bufferByteSize = frames * _recordFormat.mBytesPerFrame;

    NSLog(@"startRecording-缓存区大小:%d",bufferByteSize);

    //创建缓冲器
    for (int i = 0; i < kNumberAudioQueueBuffers; i++){
        AudioQueueAllocateBuffer(_audioQueue, bufferByteSize, &_audioBuffers[i]);
        //将 _audioBuffers[i]添加到队列中
        AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL);
    }
    // 开始录音
    AudioQueueStart(_audioQueue, NULL);
    _isRecording = YES;
    
}
- (void)setRunning:(BOOL)running {
    if (_running == running) return;
    _running = running;
    if (_running) {
        NSError *error;
        // 开始录音属性设置
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        // 属性微调
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
//                                         withOptions:AVAudioSessionCategoryOptionDuckOthers
//                                               error:nil];
        // 7大模式之最小系统
        [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeMeasurement error:&error];
        
        dispatch_async(self.taskQueue, ^{
            self.isRunning = YES;
            NSLog(@"MicrophoneSource: startRunning");
            AudioOutputUnitStart(self.componetInstance);
        });
    } else {
        // 结束录音设置
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                         withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                               error:nil];
        dispatch_sync(self.taskQueue, ^{
            self.isRunning = NO;
            NSLog(@"MicrophoneSource: stopRunning");
            AudioOutputUnitStop(self.componetInstance);
        });
    }
}
//（4）执行AudioQueueStart后，接下来的就剩下编写回调函数的内容了：
/// 相当于中断服务函数，每次录取到音频数据就进入这个函数
/// @param inUserData 相当于本类对象实例
/// @param inAQ 是调用回调函数的音频队列
/// @param inBuffer 是一个被音频队列填充新的音频数据的音频队列缓冲区，它包含了回调函数写入文件所需要的新数据
/// @param inStartTime 是缓冲区中的一采样的参考时间，对于基本的录制，你的毁掉函数不会使用这个参数
/// @param inNumPackets 是inPacketDescs参数中包描述符（packet descriptions）的数量，如果你正在录制一个VBR(可变比特率（variable bitrate））格式, 音频队列将会提供这个参数给你的回调函数，这个参数可以让你传递给AudioFileWritePackets函数. CBR (常量比特率（constant bitrate）) 格式不使用包描述符。对于CBR录制，音频队列会设置这个参数并且将inPacketDescs这个参数设置为NULL，官方解释为The number of packets of audio data sent to the callback in the inBuffer parameter.
/// @param inPacketDesc <#inPacketDesc description#>
void inputBufferHandler(void *inUserData,
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp *inStartTime,
                        UInt32 inNumPackets,
                        const AudioStreamPacketDescription *inPacketDesc)
{
//    NSLog(@"we are in the Audio Queue 回调函数\n");
    AudioRecorder *recorder = (__bridge AudioRecorder*)inUserData;
    if (inNumPackets > 0) {
        [recorder processAudioBuffer:inBuffer withQueue:inAQ
                        inNumPackets:inNumPackets inPacketDesc:inPacketDesc];
    }
    if (recorder.isRecording) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

// 采集回调函数
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        AudioRecorder *source = (__bridge AudioRecorder *)inRefCon;
        if (!source) return -1;

        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;

        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;

        OSStatus status = AudioUnitRender(source.componetInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);

        if (source.muted) {
            for (int i = 0; i < buffers.mNumberBuffers; i++) {
                AudioBuffer ab = buffers.mBuffers[i];
                memset(ab.mData, 0, ab.mDataByteSize);
            }
        }

        if (!status) {
            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
                [source.delegate captureOutput:source audioData:[NSData dataWithBytes:buffers.mBuffers[0].mData
                                                                               length:buffers.mBuffers[0].mDataByteSize]];
            }
        }
        
        return status;
    }
}
- (void)processAudioBuffer:(AudioQueueBufferRef )audioQueueBufferRef
                 withQueue:(AudioQueueRef )audioQueueRef
              inNumPackets:(UInt32) inNumPackets
              inPacketDesc:(const AudioStreamPacketDescription *)inPacketDesc
{
    NSMutableData * dataM = [NSMutableData dataWithBytes:audioQueueBufferRef->mAudioData
                                                  length:audioQueueBufferRef->mAudioDataByteSize];
    
    if (dataM.length < 960) { //处理长度小于960的情况,此处是补00
        Byte byte[] = {0x00};
        NSData * zeroData = [[NSData alloc] initWithBytes:byte length:1];
        for (NSUInteger i = dataM.length; i < 960; i++) {
            [dataM appendData:zeroData];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
        [self.delegate captureOutput:self audioData:dataM];
    }
    
    // 写入文件
    [[XDXAudioFileHandler getInstance] writeFileWithData:dataM];
    
//    NSLog(@"实时录音的数据--%@", dataM);
//    音高处理
//    [[MSBAudioManager share] pitchProcess:dataM];
//    NSArray<MSBVoicePitchInfo *> *pitchresult =  [_audioQueuePlayer.audioProcesser pitchProcess:dataM];
//    NSArray<MSBVoicePitchInfo *> *pitchresult =  [[MSBAudioManager share] pitchProcess:dataM];
    
//    for (MSBVoicePitchInfo *info in pitchresult) {
//        NSLog(@"实时录音的数据 Pitch ： -- pitch:%f", info.freq);
//    }
    
//    OSStatus status = AudioFileWritePackets(m_recordFile,
//                                            false,
//                                            inNumBytes,
//                                            inPacketDesc,
//                                            m_recordCurrentPacket,
//                                            &ioNumPackets,
//                                            inBuffer);
//    
//    if (status == noErr) {
//        m_recordCurrentPacket += ioNumPackets;  // 用于记录起始位置
//    }else {
//        NSLog(@"%@:%s - write file status = %d \n",kModuleName,__func__,(int)status);
//    }
    
    //此处是发通知将dataM 传递出去，
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"EYRecordNotifacation" object:@{@"data" : dataM}];
    
//    // 实时录音实时播放，不能使用通知的方式传递数据：CPU 100%，播放没有声音
//    __block  __weak typeof(self) wself = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [wself.audioQueuePlayer playWithData:dataM];
//    });
    

}


#pragma mark File Path
- (NSString *)createFilePath {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy_MM_dd__HH_mm_ss";
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    
    NSArray *searchPaths    = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask,
                                                                  YES);
    
    NSString *documentPath  = [[searchPaths objectAtIndex:0] stringByAppendingPathComponent:@"Voice"];
    
    // 先创建子目录. 注意,若果直接调用AudioFileCreateWithURL创建一个不存在的目录创建文件会失败
    // 判断目录是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:documentPath]) {
        [fileManager createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *fullFileName  = [NSString stringWithFormat:@"%@.aac",date];
    NSString *filePath      = [documentPath stringByAppendingPathComponent:fullFileName];
    
    
    return filePath;
}

- (AudioFileID)createAudioFileWithFilePath:(NSString *)filePath
                                 AudioDesc:(AudioStreamBasicDescription)audioDesc {
    CFURLRef url            = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
    NSLog(@"%s - record file path:%@",__func__,filePath);
    
    AudioFileID audioFile;
    // create the audio file
    OSStatus status = AudioFileCreateWithURL(url,
                                             kAudioFileCAFType,
                                             &audioDesc,
                                             kAudioFileFlags_EraseFile,
                                             &audioFile);
    if (status != noErr) {
        NSLog(@":%s - AudioFileCreateWithURL Failed, status:%d",__func__,(int)status);
    }
    
    CFRelease(url);
    
    return audioFile;
}
-(void)stopRecording
{
    if (_isRecording)
    {
        _isRecording = NO;
        
        //停止录音队列和移除缓冲区,以及关闭session，这里无需考虑成功与否
        AudioQueueStop(_audioQueue, true);
        //移除缓冲区,true代表立即结束录制，false代表将缓冲区处理完再结束
        AudioQueueDispose(_audioQueue, true);
    }
    
    NSLog(@"停止录音");
    
    [[XDXAudioFileHandler getInstance] stopWriteToFile];
}

#pragma mark - Timer
- (void)timerAction {
    
}

#pragma mark - 通知回调
- (void)handleAudioComponentCreationFailure {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"处理音频组件创建失败");
    });
}
- (void)handleInterruption:(NSNotification *)notification {
    NSInteger reason = 0;
    NSString *reasonStr = @"";
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            if (self.isRunning) {
                dispatch_sync(self.taskQueue, ^{
                    NSLog(@"MicrophoneSource: stopRunning");
                    AudioOutputUnitStop(self.componetInstance);
                });
            }
        }
        if (reason == AVAudioSessionInterruptionTypeEnded) {
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            NSNumber *seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
            switch ([seccondReason integerValue]) {
            case AVAudioSessionInterruptionOptionShouldResume:
                if (self.isRunning) {
                    dispatch_async(self.taskQueue, ^{
                        NSLog(@"MicrophoneSource: startRunning");
                        AudioOutputUnitStart(self.componetInstance);
                    });
                }
                // Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                break;
            default:
                break;
            }
        }
    };
    
    NSLog(@"handleInterruption: %@ reason %@", [notification name], reasonStr);
}

- (void)handleRouteChange:(NSNotification *)notification {
    AVAudioSession *session = [ AVAudioSession sharedInstance];
        NSString *seccReason = @"";
        NSInteger reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
        
        switch (reason) {
        
            case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            
                seccReason = @"The route changed because no suitable route is now available for the specified category.";
            
                break;
        
            case AVAudioSessionRouteChangeReasonWakeFromSleep:
            
                seccReason = @"The route changed when the device woke up from sleep.";
            
                break;
        
            case AVAudioSessionRouteChangeReasonOverride:
            
                seccReason = @"The output route was overridden by the app.";
            
                break;
        
            case AVAudioSessionRouteChangeReasonCategoryChange:
            
                seccReason = @"The category of the session object changed.";
            
                break;
       
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            
                seccReason = @"The previous audio output path is no longer available.";
            
                break;
       
            case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            
                seccReason = @"A preferred new audio output path is now available.";
            
                break;
        
            case AVAudioSessionRouteChangeReasonUnknown:
        
            default:
           
                seccReason = @"The reason for the change is unknown.";
            break;
        }
        NSLog(@"handleRouteChange reason is %@", seccReason);

        NSArray* inputs = [[AVAudioSession sharedInstance] currentRoute].inputs;
        NSArray* output = [[AVAudioSession sharedInstance] currentRoute].outputs;
        NSLog(@"current inputs:%@",inputs);
        NSLog(@"current output:%@",output);

        NSArray* availableInputs = [[AVAudioSession sharedInstance] availableInputs];
        NSLog(@"current available availableInputs:%@",availableInputs);

        NSLog(@"hasMicphone:%d",[MSBAudioTools hasMicphone]);

        NSLog(@"hasHeadset:%d",[MSBAudioTools hasHeadset]);
        
    //    for (AVAudioSessionPortDescription* desc in availableInputs) {
    //        if ([desc.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {// 内置麦克风
    //            NSLog(@"current available inputs：AVAudioSessionPortBuiltInMic");
    //        }else if([desc.portType isEqualToString:AVAudioSessionPortLineIn]){
    //            NSLog(@"current available inputs:AVAudioSessionPortLineIn");
    //        }else if ([desc.portType isEqualToString:AVAudioSessionPortHeadsetMic]){// 耳机线中的麦克风
    //            NSLog(@"current available inputs:AVAudioSessionPortHeadsetMic");
    //        }
    //    }
    //
    //    for (AVAudioSessionPortDescription *desc in inputArray) {
    //        if ([desc.portType isEqualToString:self.audioSessionPort]) {
    //            NSError *error;
    //            [[AVAudioSession sharedInstance] setPreferredInput:desc error:&error];
    //        }
    //    }
        
        AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count] ? session.currentRoute.inputs : nil objectAtIndex:0];
        NSLog(@"session.currentRoute.inputs:%@ input.portType:%@",session.currentRoute.inputs,input.portType);
        if (input.portType == AVAudioSessionPortHeadsetMic) {
            NSLog(@"input type is headsetMic");
        }else if (input.portType == AVAudioSessionPortBuiltInMic){
            NSLog(@"input type is builtInMic");
        }
}
@end
