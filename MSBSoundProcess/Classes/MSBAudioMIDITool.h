//
//  MSBAudioMIDITool.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSBAudioMIDITool : NSObject
/// 频率转midi值
/// @param frequency 频率
+ (int) snapFreqToMIDI:(float) frequency;
+ (NSString*) midiToString: (int) midiNote;

@end

NS_ASSUME_NONNULL_END
