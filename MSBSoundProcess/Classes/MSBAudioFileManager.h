//
//  MSBFileManager.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSBAudioFileManager : NSObject
@property(nonatomic, strong)    NSFileHandle *audioFileHandle;
@property (nonatomic, copy)     NSString *audioFilePath;
// 3
- (NSString *)stopWrite;
// 2
- (void)writingData:(NSData *)fileStream;
//1. 初始化file
- (void)initSetupRecordAudioFile;

- (NSString *) createFilePathWithDictionaryNameAutomatic:(NSString *)dicName fileName:(NSString*)fileName;
@end

NS_ASSUME_NONNULL_END
