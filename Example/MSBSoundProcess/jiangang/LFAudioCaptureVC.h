//
//  LFAudioCaptureVC.h
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/2/14.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LFAudioCaptureVC : UIViewController

@end

int pcmfileToWavfile(const char *pcmfilePath, const char *wavfilePath);
void* pcmToWav(const void *pcm, unsigned int pcmlen, unsigned int *wavlen);
void* ReadFile(const char *path, unsigned int *len);
NS_ASSUME_NONNULL_END
