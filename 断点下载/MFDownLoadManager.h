//
//  MFDownLoadManager.h
//  断点下载
//
//  Created by 大虾咪 on 2017/9/7.
//  Copyright © 2017年 大虾咪. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFDownLoadManager : NSObject

+ (__kindof MFDownLoadManager *)sharedInstance;

//模仿AFNetwork，把下载封装到一个方法，然后使用不同的block来实现下载进度，成功，失败后的回调。
- (void)downLoad:(NSString *)url
    saveFilePath:(NSString *)filePath
        progress:(void(^)(NSString *))progressBlock
         success:(void(^)(NSString *))succssBlock
           faile:(void(^)(NSError *))faileBlock;


-(void)suspendTask;


@end
