//
//  MSBRecordManager.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/11/2.
//

#import <Foundation/Foundation.h>
#import "MSBAudioKitInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSBRecordManager : NSObject
@property (nonatomic, weak, nullable)id<MSBAudioKitInterface> delegate;
- (void)startRecord;
- (void)stopRecord;
- (void)pauseRecord;
- (void)resumeRecord;

- (void)recordOutputAudioData:(NSData *)outputdata;

- (NSString*)getCurrentWavVoiceFilePath;
@end

NS_ASSUME_NONNULL_END
