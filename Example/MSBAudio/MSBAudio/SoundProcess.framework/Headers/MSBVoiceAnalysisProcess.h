// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from voicebeating.djinni

#import "MSBVoiceAnalysisInfo.h"
#import <Foundation/Foundation.h>
@class MSBVoiceAnalysisProcess;


@interface MSBVoiceAnalysisProcess : NSObject

+ (nullable MSBVoiceAnalysisProcess *)createVoiceAnalysisProcess;

- (int32_t)init:(int32_t)sampleRate
        channel:(int32_t)channel;

- (nonnull MSBVoiceAnalysisInfo *)getVoiceAnalysisInfoRealtime:(nonnull NSData *)inData
                                                   inSampleCnt:(int32_t)inSampleCnt;

@end
