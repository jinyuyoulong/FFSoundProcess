//
//  XBPCMPlayer.m
//  XBVoiceTool
//
//  Created by xxb on 2018/7/2.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import "XBPCMPlayer.h"

@interface XBPCMPlayer ()
@end

@implementation XBPCMPlayer

//从文件地址中读取pcm到内存中;
- (instancetype)initWithPCMFilePath:(NSString *)filePath rate:(XBAudioRate)rate channels:(XBAudioChannel)channels bit:(XBAudioBit)bit
{
    if (self = [super init])
    {
        self.filePath = filePath;
        self.player = [[XBAudioUnitPlayer alloc] initWithRate:rate bit:bit channel:channels];
        self.reader = [XBAudioPCMDataReader new];
    }
    return self;
}

- (instancetype)initWithPCMFileData:(NSMutableData *)filedata rate:(XBAudioRate)rate channels:(XBAudioChannel)channels bit:(XBAudioBit)bit;
{
    if (self = [super init])
    {
        self.dataStore =[NSData dataWithData:filedata]; //拷贝;
        self.player = [[XBAudioUnitPlayer alloc] initWithRate:rate bit:bit channel:channels];
        self.reader = [XBAudioPCMDataReader new];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"XBPCMPlayer销毁");
    [self.player stop];
    self.player = nil;
}
- (void)play_init
{
    if (self.player.bl_input == nil)
    {
        typeof(self) __weak weakSelf = self;
        self.player.bl_input = ^(AudioBufferList *bufferList)
        {
            if(self.isPause == NO)
            {
//                NSLog(@"xxxxxinputCallBackTime:%f",[[NSDate date] timeIntervalSince1970]);
                AudioBuffer buffer = bufferList->mBuffers[0];
                int len = buffer.mDataByteSize;
                int readLen = [weakSelf.reader readDataFrom:weakSelf.dataStore len:len forData:buffer.mData];
                buffer.mDataByteSize = readLen;
                if (readLen == 0)
                {
                    /*
                    //填写空数据;
                    self.player.bl_input = ^(AudioBufferList *bufferList)
                    {
                        AudioBuffer buffer = bufferList->mBuffers[0];
                        int len = buffer.mDataByteSize;
                        buffer.mDataByteSize = len;
                        memset(buffer.mData,0,buffer.mDataByteSize);
                    };
                     */
                    
                  // [weakSelf stop];
                   if ([weakSelf.delegate respondsToSelector:@selector(playToEnd:)])
                   {
                        [weakSelf.delegate playToEnd:weakSelf];
                   }
                }
            }
        };
    }
    [self.player start_init];
}
- (void)play_init2
{
    typeof(self) __weak weakSelf = self;
    self.player.bl_input = ^(AudioBufferList *bufferList)
    {
//            NSLog(@"xxxxxinputCallBackTime:%f",[[NSDate date] timeIntervalSince1970]);
        AudioBuffer buffer = bufferList->mBuffers[0];
        int len = buffer.mDataByteSize;
        int readLen = [weakSelf.reader readDataFrom:weakSelf.dataStore len:len forData:buffer.mData];
        buffer.mDataByteSize = readLen;
        if (readLen == 0)
        {
            //填写空数据;
            self.player.bl_input = ^(AudioBufferList *bufferList)
            {
                AudioBuffer buffer = bufferList->mBuffers[0];
                int len = buffer.mDataByteSize;
                buffer.mDataByteSize = len;
                memset(buffer.mData,0,buffer.mDataByteSize);
            };
            
          // [weakSelf stop];
          // if ([weakSelf.delegate respondsToSelector:@selector(playToEnd:)])
          // {
          //      [weakSelf.delegate playToEnd:weakSelf];
          // }
        }
    };
}
- (void)play
{
    /*
    if (self.player.bl_input == nil)
    {
        typeof(self) __weak weakSelf = self;
        self.player.bl_input = ^(AudioBufferList *bufferList) {
//            NSLog(@"xxxxxinputCallBackTime:%f",[[NSDate date] timeIntervalSince1970]);
            AudioBuffer buffer = bufferList->mBuffers[0];
            int len = buffer.mDataByteSize;
            int readLen = [weakSelf.reader readDataFrom:weakSelf.dataStore len:len forData:buffer.mData];
            buffer.mDataByteSize = readLen;
            if (readLen == 0)
            {
                [weakSelf stop];
                if ([weakSelf.delegate respondsToSelector:@selector(playToEnd:)])
                {
                    [weakSelf.delegate playToEnd:weakSelf];
                }
            }
        };
    }
     */
    [self.player start];
    self.isPlaying = YES;
}
- (void)stop
{
    
    self.player.bl_input = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPreferredIOBufferDuration*0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player stop];
        self.isPlaying = NO;
    });
}

- (void)pause
{
    if(self.isPause == YES)
    {
        self.isPause = NO;
    }
    else if(self.isPause == NO)
    {
        self.isPause = YES;
    }
}


#pragma mark - 方法重写
- (void)setFilePath:(NSString *)filePath
{
    _filePath = filePath;
    self.dataStore = [NSData dataWithContentsOfFile:filePath];
}


@end
