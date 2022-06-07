//
//  MSBAudioTools.h
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/3/31.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSBAudioTools : NSObject
+ (BOOL)hasMicphone;
+ (BOOL)hasHeadset;
@end

NS_ASSUME_NONNULL_END
