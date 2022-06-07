//
//  AudioPlayer.h
//  AudioQueueCaptureOC
//
//  Created by 范金龙 on 2021/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioPlayer : NSObject
@property (nonatomic, strong)NSString *audioPath;

- (instancetype)initWithPath:(NSString*)path;

-(void)playWithPeripheral;
- (void)playLoundspeaker;
-(void)pause;
-(void)stop;
- (void) setupAudioPlayerWithData:(NSData *)data;
- (void)setupAudioPlayerWithPath:(NSString *)path;
- (void)playAAC;
@end

NS_ASSUME_NONNULL_END
