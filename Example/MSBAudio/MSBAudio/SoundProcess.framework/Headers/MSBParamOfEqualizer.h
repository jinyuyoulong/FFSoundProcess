// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from voicebeating.djinni

#import <Foundation/Foundation.h>

@interface MSBParamOfEqualizer : NSObject
- (nonnull instancetype)initWithCenterfreq:(float)centerfreq
                                     width:(float)width
                                      gain:(float)gain;
+ (nonnull instancetype)paramOfEqualizerWithCenterfreq:(float)centerfreq
                                                 width:(float)width
                                                  gain:(float)gain;

@property (nonatomic, readonly) float centerfreq;

@property (nonatomic, readonly) float width;

@property (nonatomic, readonly) float gain;

@end
