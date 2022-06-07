//
//  MSBFileManager.m
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/2/9.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import "MSBAudioFileManager.h"

@implementation MSBAudioFileManager
- (void)writeFile:(NSData *)data {
    NSFileHandle *inFile,*outFile;
    NSData *buffer;
    NSString *fileContent = @"这些是文件内容,这些是文件内容,这些是文件内容,这些是文件内容,这些是文件内容";
    NSFileManager *fm = [NSFileManager defaultManager];
    //创建一个文件
    [fm createFileAtPath:@"testFile.txt" contents:[fileContent dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    //创建一个需要写入的文件
    [fm createFileAtPath:@"outFile.txt" contents:nil attributes:nil];
    
    //读取文件
    inFile = [NSFileHandle fileHandleForReadingAtPath:@"testFile.txt"];
    //写入文件
    outFile = [NSFileHandle fileHandleForWritingAtPath:@"outFile.txt"];
    
    if(inFile!=nil){
        //读取文件内容
        buffer = [inFile readDataToEndOfFile];
        
        //将文件的字节设置为0，因为他可能包含数据
        [outFile truncateFileAtOffset:0];
        
        //将读取的内容内容写到outFile.txt中
        [outFile writeData:buffer];
        
        //关闭输出
        [outFile closeFile];
        
        //验证outFile内容
        NSLog(@"%@",[NSString stringWithContentsOfFile:@"outFile.txt" encoding:NSUTF8StringEncoding error:NULL]);
        
        
        //创建一个新的文件用来循环写入
        [fm createFileAtPath:@"outFile2.txt" contents:nil attributes:nil];
        
        //打开一个新的输出
        outFile = [NSFileHandle fileHandleForWritingAtPath:@"outFile2.txt"];
        
        //设置一个循环写入10条数据，每条数据都再后面添加上而不是覆盖
        for (int i = 0; i<10; i++) {
            //将偏移量设置为文件的末尾
            [outFile seekToEndOfFile];
            //写入数据
            [outFile writeData:buffer];
        }
        
        //验证内容
        NSLog(@"outFile2:%@",[NSString stringWithContentsOfFile:@"outFile2.txt" encoding:NSUTF8StringEncoding error:NULL]);
        
        //关闭所有
        [outFile closeFile];
        [inFile closeFile];
    }
}
@end
