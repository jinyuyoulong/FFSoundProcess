// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from voicebeating.djinni

#import <Foundation/Foundation.h>

@interface MSBVoiceNoteInfo : NSObject
- (nonnull instancetype)initWithStartTimeMs:(int32_t)startTimeMs
                                  endTimeMs:(int32_t)endTimeMs
                            startFrameIndex:(int32_t)startFrameIndex
                              endFrameIndex:(int32_t)endFrameIndex
                                       note:(float)note;
+ (nonnull instancetype)voiceNoteInfoWithStartTimeMs:(int32_t)startTimeMs
                                           endTimeMs:(int32_t)endTimeMs
                                     startFrameIndex:(int32_t)startFrameIndex
                                       endFrameIndex:(int32_t)endFrameIndex
                                                note:(float)note;

@property (nonatomic, readonly) int32_t startTimeMs;

@property (nonatomic, readonly) int32_t endTimeMs;

@property (nonatomic, readonly) int32_t startFrameIndex;

@property (nonatomic, readonly) int32_t endFrameIndex;

@property (nonatomic, readonly) float note;

@end