//
//  MSBAudioTensorflowManager.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/7/3.
//

#import <Foundation/Foundation.h>
#import "MSBAudioKitInterface.h"

NS_ASSUME_NONNULL_BEGIN


@interface MSBAudioTensorflowManager : NSObject
@property (nonatomic, weak)id<MSBAudioKitInterface> delegate;

+(MSBAudioTensorflowManager*)shared;
- (void)feizhouguPlay;
- (void)feizhouguPause;

- (void)coveredPCMtoWavFile:(NSString*)pcmPath;
- (void)coveredWAVtoMP3File:(NSString *)wavFile;
@end

NS_ASSUME_NONNULL_END
