// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from voicebeating.djinni

#import "MSBPlayModeT.h"
#import <Foundation/Foundation.h>

@interface MSBVoiceNodeInfo : NSObject
- (nonnull instancetype)initWithInputStartTime:(int32_t)inputStartTime
                                  inputEndTime:(int32_t)inputEndTime
                               outputStartTime:(int32_t)outputStartTime
                                         scale:(float)scale
                                 outputEndTime:(int32_t)outputEndTime
                                      playMode:(MSBPlayModeT)playMode;
+ (nonnull instancetype)voiceNodeInfoWithInputStartTime:(int32_t)inputStartTime
                                           inputEndTime:(int32_t)inputEndTime
                                        outputStartTime:(int32_t)outputStartTime
                                                  scale:(float)scale
                                          outputEndTime:(int32_t)outputEndTime
                                               playMode:(MSBPlayModeT)playMode;

@property (nonatomic, readonly) int32_t inputStartTime;

@property (nonatomic, readonly) int32_t inputEndTime;

@property (nonatomic, readonly) int32_t outputStartTime;

@property (nonatomic, readonly) float scale;

@property (nonatomic, readonly) int32_t outputEndTime;

@property (nonatomic, readonly) MSBPlayModeT playMode;

@end
