// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from voicebeating.djinni

#import <Foundation/Foundation.h>

@interface MSBVoiceVadInfo : NSObject
- (nonnull instancetype)initWithTimeMs:(int32_t)timeMs
                                 vocal:(BOOL)vocal;
+ (nonnull instancetype)voiceVadInfoWithTimeMs:(int32_t)timeMs
                                         vocal:(BOOL)vocal;

@property (nonatomic, readonly) int32_t timeMs;

@property (nonatomic, readonly) BOOL vocal;

@end
