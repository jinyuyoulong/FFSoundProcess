// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from voicebeating.djinni

#import <Foundation/Foundation.h>
@class MSBVoicePreprocess;


@interface MSBVoicePreprocess : NSObject

+ (nullable MSBVoicePreprocess *)createVoicePreprocess;

- (int32_t)init:(int32_t)sampleRate
        channel:(int32_t)channel;

- (nonnull NSData *)preProcess:(nonnull NSData *)inData
                   inSampleCnt:(int32_t)inSampleCnt;

- (nonnull NSData *)preProcessAgc:(nonnull NSData *)inData
                      inSampleCnt:(int32_t)inSampleCnt;

- (BOOL)audioMix:(nonnull NSArray<NSString *> *)audioNames
          output:(nonnull NSString *)output;

@end
