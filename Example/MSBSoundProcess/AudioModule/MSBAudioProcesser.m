//
//  MSBAudioProcesser.m
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/2/10.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import "MSBAudioProcesser.h"
#import "AudioRecorder.h"
@interface MSBAudioProcesser ()<AudioRecorderDelegate>

@end
@implementation MSBAudioProcesser

- (void)captureOutput:(nullable AudioRecorder *)capture audioData:(nullable NSData *)audioData {
    NSLog(@"%@",audioData);
}

@end
