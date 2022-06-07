//
//  msbaudioai.h
//  msbaudioai
//
//  Created by Admin on 2021/6/30.
//

#import <Foundation/Foundation.h>

//! Project version number for msbaudioai.
FOUNDATION_EXPORT double msbaudioaiVersionNumber;

//! Project version string for msbaudioai.
FOUNDATION_EXPORT const unsigned char msbaudioaiVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <msbaudioai/PublicHeader.h>


//AudioAiBlock回调 参数为结果类型id

typedef void(^AudioAiBlock)(int);

@interface MSBAudioAi : NSObject

@property AudioAiBlock block;

//@property (nonatomic,assign) float speedratio;
//@property (nonatomic,assign) int instrumenttype;
//@property (nonatomic,assign) int soundtype;

@property NSString * tflitepath;
@property NSString * recordpath;
@property NSString * logpath;


//初始化类
-(void)msbinitaudioai:(NSString *)filePath andRecordPath:(NSString *) recordPath andLogPath:(NSString *) logPath;

-(void)msbplay;

-(void)msbpause;



@end
