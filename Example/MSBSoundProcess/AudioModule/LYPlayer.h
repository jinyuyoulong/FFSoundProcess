//
//  LYPlayer.h
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/2/14.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//


#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@class LYPlayer;
@protocol LYPlayerDelegate <NSObject>

- (void)onPlayToEnd:(LYPlayer *)player;

@end


@interface LYPlayer : NSObject

@property (nonatomic, weak) id<LYPlayerDelegate> delegate;
- (void)setupAudioPlayerWithPath:(NSString *)path;
- (void)play;

- (double)getCurrentTime;
- (void)playWithData:(NSData*)data;

@end

NS_ASSUME_NONNULL_END
