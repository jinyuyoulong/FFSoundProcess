////
////  FFAVPlayer.m
////  MSBSoundProcess_Example
////
////  Created by 范金龙 on 2021/2/15.
////  Copyright © 2021 jinyuyoulong. All rights reserved.
////
//
//#import "FFAVPlayer.h"
////1.AVPlayer需要通过AVPlayerItem来关联需要播放的媒体。
//
//#import <AVFoundation/AVFoundation.h>
//@interface FFAVPlayer()
//@property (nonatomic, strong)AVPlayerItem *item;
//@property (nonatomic, strong)AVPlayer *player;
//@end
//@implementation FFAVPlayer
//
//- (instancetype)initWithURL:(NSURL*)urlStr
//{
//    self = [super init];
//    if (self) {
//        [self setupWithURL:urlStr];
//
//    }
//    return self;
//}
//
//- (void)setupWithURL:(NSURL*)urlStr {
//    _item = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:urlStr]];
//    _player = [[AVPlayer alloc] initWithPlayerItem:item];
//
//    //2.在准备播放前，通过KVO添加播放状态改变监听
//    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//
//    //3.KVO监听音乐缓冲状态：
//    [self.player.currentItem addObserver:self
//                              forKeyPath:@"loadedTimeRanges"
//                                 options:NSKeyValueObservingOptionNew
//                                 context:nil];
//}
//
//
////处理KVO回调事件：
//-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
//{
//    if ([keyPath isEqualToString:@"status"]) {
//        switch (self.player.status) {
//            case AVPlayerStatusUnknown:
//            {
//                NSLog(@"未知转态");
//            }
//                break;
//            case AVPlayerStatusReadyToPlay:
//            {
//                NSLog(@"准备播放");
//            }
//                break;
//            case AVPlayerStatusFailed:
//            {
//                NSLog(@"加载失败");
//            }
//                break;
//
//            default:
//                break;
//        }
//
//    }
//
//    //...
//    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
//
//        NSArray * timeRanges = self.player.currentItem.loadedTimeRanges;
//        //本次缓冲的时间范围
//        CMTimeRange timeRange = [timeRanges.firstObject CMTimeRangeValue];
//        //缓冲总长度
//        NSTimeInterval totalLoadTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
//        //音乐的总时间
//        NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
//        //计算缓冲百分比例
//        NSTimeInterval scale = totalLoadTime/duration;
//        //更新缓冲进度条
//        //        self.loadTimeProgress.progress = scale;
//    }
//}
//
////##注意：kvo添加之后，在使用结束之后，记得移除！！！！
//- (void)dealloc
//{
//    [self removeObserver:self forKeyPath:@"status"];
//    [self removeObserver:self forKeyPath:@"loadedTimeRanges"];
//
//    //10.AVPlayer的内存的释放
//    //用完是需要注意要对其进行释放：写在你退出的点击事件当中，比如说要pop视图了，另外：注意：没有释放播放器的playeritem 所以还在缓冲 释放播放器时加上两句
//    self.player=nil;
//    [playerItem cancelPendingSeeks];
//    [playerItem.asset cancelLoading];
//    [player.currentItem cancelPendingSeeks];
//    [player.currentItem.asset cancelLoading];
//}
////4.开始播放后，通过KVO添加播放结束事件监听
//
////5.开始播放时，通过AVPlayer的方法监听播放进度，并更新进度条（定期监听的方法）
//// ,注意：有时候，我们点击播放了，但是半天还没有播放，那么究竟什么时候才真正开始播放，能不能检测到？就用下面这个方法，经过验证，当开始执行这个方法的时候，就真正开始播放了：
////(1）方法传入一个CMTime结构体，每到一定时间都会回调一次，包括开始和结束播放
////(2）如果block里面的操作耗时太长，下次不一定会收到回调，所以尽量减少block的操作耗时
////(3）方法会返回一个观察者对象，当播放完毕时需要移除这个观察者
//
//- (void)play {
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(playFinished:)
//                                                 name:AVPlayerItemDidPlayToEndTimeNotification
//                                               object:_player.currentItem];
//    //8.监听AVPlayer播放完成通知
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(playbackFinished:)
//                                                 name:AVPlayerItemDidPlayToEndTimeNotification
//                                               object:songItem];
//
//
//}
//- (void)playFinished:(NSNotification*)notif {
//    __weak typeof(self) weakSelf = self;
//    id timeObserve =[self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
//        //当前播放的时间
//        float current = CMTimeGetSeconds(time);
//        //总时间
//        float total = CMTimeGetSeconds(item.duration);
//        if (current) {
//            float progress = current / total;
//            //更新播放进度条
//            weakSelf.playSlider.value = progress;
//        }
//    }];
//    //##使用结束之后移除观察者：
//    if (timeObserve) {
//        [player removeTimeObserver:_timeObserve];
//        timeObserve = nil;
//    }
//}
//
////6.用户拖动进度条，修改播放进度
//- (void)playSliderValueChange:(UISlider *)sender
//{
//    //根据值计算时间
//    float time = sender.value * CMTimeGetSeconds(self.player.currentItem.duration);
//    //跳转到当前指定时间
//    [self.player seekToTime:CMTimeMake(time, 1)];
//}
////7.上一首、下一首：这里我们有两种方式可以实现，
////一种是由你自行控制下一首歌曲的item，将其替换到当前播放的item
//
////[player replaceCurrentItemWithPlayerItem:songItem];
//
////另一种是使用AVPlayer的子类AVQueuePlayer来播放多个item，调用advanceToNextItem来播放下一首音乐
//
////NSArray * items = @[item1, item2, item3];
////AVQueuePlayer * queuePlayer = [[AVQueuePlayer alloc]initWithItems:items];
//
//
//- (void)playbackFinished:(NSNotification *)notice {
//    BASE_INFO_FUN(@"播放完成");
////    [self playNext];
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
////9.播放完毕后，一般都会进行播放下一首的操作。
////播放下一首前，别忘了移除这个item的观察者：
//
//
//@end
