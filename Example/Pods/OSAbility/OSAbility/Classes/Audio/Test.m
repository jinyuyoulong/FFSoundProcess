//
//  Test.m
//  OSAbility
//
//  Created by 范金龙 on 2021/12/27.
//

#import "Test.h"
#import <OSAbility/OSAbility-Swift.h>

@implementation Test
- (instancetype)init {
    
    if (self = [super init]) {
        self = [[Test alloc] init];
        OSAudioSessionManager.shared.originModel = [[AudioSessionModel alloc] initWithCategory:AVAudioSessionCategoryRecord
                                                                                 options:AVAudioSessionCategoryOptionDefaultToSpeaker
                                                                                 mode:AVAudioSessionModeDefault];
    }
    return self;
}
@end
