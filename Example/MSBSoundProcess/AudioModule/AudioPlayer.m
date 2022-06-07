//
//  AudioPlayer.m
//  AudioQueueCaptureOC
//
//  Created by 范金龙 on 2021/1/19.
//

#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
@interface AudioPlayer()<AVAudioPlayerDelegate>
@property (nonatomic, strong)AVAudioPlayer *audioPlayer;

@end

@implementation AudioPlayer

- (instancetype)initWithPath:(NSString*)path
{
    self = [super init];
    if (self) {
        self.audioPath = path;
    }
    return self;
}

/**
 *  创建播放器
 *
 *  @return 音频播放器
 */
//-(AVAudioPlayer *)audioPlayer {
//    if (!_audioPlayer) {
////        NSString *filePath =[ [NSBundle mainBundle]pathForResource:@"2021_01_19__14_59_18" ofType:@"aac"];
////        NSLog(@"%@",filePath);
//        
//        NSError *error=nil;
//        //初始化播放器，注意这里的Url参数只能时文件路径，不支持HTTP Url
//        _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:_audioPath] error:&error];
//        //设置播放器属性
//        _audioPlayer.numberOfLoops=0;//设置为0不循环
//        _audioPlayer.delegate=self;
//        [_audioPlayer prepareToPlay];//加载音频文件到缓存
//        if(error){
//            NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
//            return nil;
//        }
//    }
//    return _audioPlayer;
//}
- (void)setupAudioPlayerWithPath:(NSString *)path {
    self.audioPath = path;
    
    NSError *error=nil;
    //初始化播放器，注意这里的Url参数只能时文件路径，不支持HTTP Url
    _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    //设置播放器属性
    _audioPlayer.numberOfLoops=0;//设置为0不循环
    _audioPlayer.delegate=self;
    [_audioPlayer prepareToPlay];//加载音频文件到缓存
    if(error){
        NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
        return;
    }
}

- (void) setupAudioPlayerWithData:(NSData *)data {
    NSError *error=nil;
    //初始化播放器，注意这里的Url参数只能时文件路径，不支持HTTP Url
    _audioPlayer = [[AVAudioPlayer alloc] initWithData:data fileTypeHint:AVFileTypeAppleM4A error:&error];
    //设置播放器属性
    _audioPlayer.numberOfLoops=0;//设置为0不循环
    _audioPlayer.delegate=self;
    [_audioPlayer prepareToPlay];//加载音频文件到缓存
    if(error){
        NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
        return;
    }
}

- (void)playAAC {
    AVAudioEngine * audioEngine = [[AVAudioEngine alloc] init];
    AVAudioPlayerNode* player = [[AVAudioPlayerNode alloc] init];
    NSError *error;
    AVAudioFile* audioFile =  [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath: self.audioPath] error:&error];
    
    AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat
                                                             frameCapacity:(AVAudioFrameCount)audioFile.length];

    if (error) {
        return;
    }
    [audioFile readIntoBuffer:buffer error:&error];
    if (error) {
        return;
    }
    [audioEngine attachNode:player];
    [audioEngine connect:player to:audioEngine.mainMixerNode format:buffer.format];
    [audioEngine startAndReturnError:&error];
    [player play];
    [player scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
}
/**
 *  播放音频
 */
-(void)playWithPeripheral {
    if (![self.audioPlayer isPlaying]) {
        //解决音量小的问题
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError *err = nil;
        //解决录音和播放不能同时共存的问题，默认使用耳机或者听筒播放
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
        [self.audioPlayer play];
//        self.timer.fireDate=[NSDate distantPast];//恢复定时器
    }
}

/// 扩音器
- (void)playLoundspeaker {
    if (![self.audioPlayer isPlaying]) {
        //解决音量小的问题
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError *err = nil;
        //解决音量小的问题
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:&err];
        [self.audioPlayer play];
    }
}
/**
 *  暂停播放
 */
-(void)pause{
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer pause];
        //暂停定时器，注意不能调用invalidate方法，此方法会取消，之后无法恢复
//        self.timer.fireDate=[NSDate distantFuture];
       
    }
}
- (void)stop {
    [self.audioPlayer stop];
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"音乐播放完成...");
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
    NSLog(@"音乐播放出错...%@",error.localizedDescription);
}
@end
