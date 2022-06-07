//
//  FFAudio.m
//  AudioQueueCaptureOC
//
//  Created by 范金龙 on 2021/1/16.
//  音频播放

#import "FFAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>


#define MIN_SIZE_PER_FRAME 960   //每个包的大小,室内机要求为960,具体看下面的配置信息
#define QUEUE_BUFFER_SIZE  3      //缓冲器个数
#define SAMPLE_RATE        44100  //采样频率

@interface FFAudio ()
{
    AudioQueueRef audioQueue;                                 //音频播放队列
    AudioStreamBasicDescription _audioDescription;
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE]; //音频缓存
    BOOL audioQueueBufferUsed[QUEUE_BUFFER_SIZE];             //判断音频缓存是否在使用
    NSLock *sysnLock;
    NSMutableData *tempData;
    OSStatus osState;
}


@end
@implementation FFAudio
#pragma mark - 提前设置AVAudioSessionCategoryMultiRoute 播放和录音
+ (void)initialize
{
    NSError *error = nil;
    //只想要播放:AVAudioSessionCategoryPlayback
    //只想要录音:AVAudioSessionCategoryRecord
    //想要"播放和录音"同时进行 必须设置为:AVAudioSessionCategoryMultiRoute 注：AVAudioSessionCategoryPlayAndRecord(设置这个不好使)
    BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryMultiRoute
                                                      error:&error];
    // 该设置播放有延迟
//    BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
//                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
//                                           error:&error];
    if (!ret) {
        NSLog(@"设置声音环境失败");
        return;
    }
    //启用audio session
    ret = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!ret)
    {
        NSLog(@"启动失败");
        return;
    }
}

- (void)resetPlay
{
    if (audioQueue != nil) {
        AudioQueueReset(audioQueue);
    }
}

- (void)stop
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue,true);
    }

    audioQueue = nil;
    sysnLock = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        

        //设置音频参数 具体的信息需要问后台
        _audioDescription.mSampleRate = SAMPLE_RATE;
        _audioDescription.mFormatID = kAudioFormatLinearPCM;
        _audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        //1单声道
        _audioDescription.mChannelsPerFrame = 1;
        //每一个packet一侦数据,每个数据包下的桢数，即每个数据包里面有多少桢
        _audioDescription.mFramesPerPacket = 1;
        //每个采样点16bit量化 语音每采样点占用位数
        _audioDescription.mBitsPerChannel = 16;
        
        _audioDescription.mBytesPerFrame = (_audioDescription.mBitsPerChannel / 8) * _audioDescription.mChannelsPerFrame;
        //每个数据包的bytes总数，每桢的bytes数*每个数据包的桢数
        _audioDescription.mBytesPerPacket = _audioDescription.mBytesPerFrame * _audioDescription.mFramesPerPacket;

        // 使用player的内部线程播放 新建输出
        AudioQueueNewOutput(&_audioDescription, AudioPlayerAQInputCallback,
                            (__bridge void * _Nullable)(self), nil, 0, 0, &audioQueue);

        // 设置音量增益
        AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1);
        // 设置声音增益
//        float gain = 10;
//        AudioQueueGetParameter(audioQueue, kAudioQueueParam_Volume, &gain);
        
        // 初始化需要的缓冲区
        for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
            audioQueueBufferUsed[i] = false;
            osState = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);
        }

        osState = AudioQueueStart(audioQueue, NULL);
        if (osState != noErr) {
            NSLog(@"AudioQueueStart Error");
        }
        // 设置增益
        [self setupVoice:5];
        
//        _audioProcesser = [MSBAudioManager share];//[[MSBAudioManager alloc] initWithSampleRate:44100 channel:1];
        //用通知获取音频数据，暂时不用
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAudioData:) name:@"EYRecordNotifacation" object:nil];
    }
    return self;
}
//设置音量增量//0.0 - 1.0
- (void)setupVoice:(Float32)gain {
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, gain);
}
// 通知回调
- (void)getAudioData:(NSNotification *)notification {
    if (notification.object) {
        NSData *data = [notification.object objectForKey:@"data"];
        NSLog(@"接收到数据：%@",data);
//        if (self.isStartPlay) {
            [self playWithData:data];
//        }
    }
}

// 播放数据
-(void)playWithData:(NSData *)data
{
    if (sysnLock == nil) {
        sysnLock = [[NSLock alloc]init];
    }
    [sysnLock lock];
    
//    NSData *processedData = [self preProcessAudioData:data];
//    if (processedData == nil) {
//        return;
//    }
    tempData = [NSMutableData new];
    [tempData appendData: data];
//    [tempData appendData: processedData];
    NSUInteger len = tempData.length;
    Byte *bytes = (Byte*)malloc(len);
    [tempData getBytes:bytes length: len];

    int i = 0;
    while (true) {
        if (!audioQueueBufferUsed[i]) {
            audioQueueBufferUsed[i] = true;
            break;
        }else {
            i++;
            if (i >= QUEUE_BUFFER_SIZE) {
                i = 0;
            }
        }
    }

    audioQueueBuffers[i] -> mAudioDataByteSize =  (unsigned int)len;
    // 把bytes的头地址开始的len字节给mAudioData,向第i个缓冲器
    memcpy(audioQueueBuffers[i] -> mAudioData, bytes, len);

    // 释放对象
    free(bytes);

    //将第i个缓冲器放到队列中,剩下的都交给系统了
    AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffers[i], 0, NULL);

    [sysnLock unlock];
}


//MARK: 音频降噪处理
- (NSData *)preProcessAudioData:(NSData *)data {
    
    // 不用c接口，unity有base64编码处理逻辑
//    openAudioCapture(1, 44100, 1);
    
//    [self.audioProcesser startManager];
//    NSData *processedData = [self.audioProcesser preProcess:data];
//    if (processedData == nil) {
//        return nil;
//    }
//    return processedData;
    return nil;
}
// ************************** 回调 **********************************
// 回调回来把buffer状态设为未使用
static void AudioPlayerAQInputCallback(void* inUserData,
                                       AudioQueueRef audioQueueRef,
                                       AudioQueueBufferRef audioQueueBufferRef) {

    FFAudio* audio = (__bridge FFAudio*)inUserData;

    [audio resetBufferState:audioQueueRef and:audioQueueBufferRef];
}

- (void)resetBufferState:(AudioQueueRef)audioQueueRef
                     and:(AudioQueueBufferRef)audioQueueBufferRef {
    // 防止空数据让audioqueue后续都不播放,为了安全防护一下
    if (tempData.length == 0) {
        audioQueueBufferRef->mAudioDataByteSize = 1;
        Byte* byte = audioQueueBufferRef->mAudioData;
        byte = 0;
        AudioQueueEnqueueBuffer(audioQueueRef, audioQueueBufferRef, 0, NULL);
    }

    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        // 将这个buffer设为未使用
        if (audioQueueBufferRef == audioQueueBuffers[i]) {
            audioQueueBufferUsed[i] = false;
        }
    }
}
@end
