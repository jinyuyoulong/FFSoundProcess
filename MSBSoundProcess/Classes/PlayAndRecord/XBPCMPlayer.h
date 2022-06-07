//
//  XBPCMPlayer.h
//  XBVoiceTool
//
//  Created by xxb on 2018/7/2.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header_audio.h"
#import "XBAudioUnitPlayer.h"
#import "XBAudioPCMDataReader.h"

@class XBPCMPlayer;
@protocol XBPCMPlayerDelegate <NSObject>
- (void)playToEnd:(XBPCMPlayer *)player;
@end

@interface XBPCMPlayer : NSObject
@property (nonatomic,strong) NSData *dataStore;
@property (nonatomic,strong) XBAudioUnitPlayer *player;
@property (nonatomic,strong) XBAudioPCMDataReader *reader;
@property (nonatomic,copy) NSString *filePath;
@property (nonatomic,assign) BOOL isPlaying;
@property (nonatomic,assign) BOOL isPause;
@property (nonatomic,weak) id<XBPCMPlayerDelegate>delegate;
//从文件地址中读取pcm到内存中;
- (instancetype)initWithPCMFilePath:(NSString *)filePath rate:(XBAudioRate)rate channels:(XBAudioChannel)channels bit:(XBAudioBit)bit;
//从文件data中读取pcm到内存中;
- (instancetype)initWithPCMFileData:(NSMutableData *)filedata rate:(XBAudioRate)rate channels:(XBAudioChannel)channels bit:(XBAudioBit)bit;
- (void)play_init;
- (void)play_init2;
- (void)play;
- (void)stop;
- (void)pause;
@end
