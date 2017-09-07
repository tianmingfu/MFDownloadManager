//
//  MFDownLoadManager.m
//  断点下载
//
//  Created by 大虾咪 on 2017/9/7.
//  Copyright © 2017年 大虾咪. All rights reserved.
//

#import "MFDownLoadManager.h"

/**
 指定下载路径
 */
#define DownLoadFilePath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"text.mkv"]
//已经下载完的数据长度
#define DownLoadDataLength [[[NSFileManager defaultManager] attributesOfItemAtPath:DownLoadFilePath error:nil][@"NSFileSize"] integerValue]
// 使用plist文件存储文件的总字节数
#define TotalLengthPlist [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"lenth.xml"]
typedef void (^ProgressBlock)(NSString *);
typedef void (^SuccssBlock)(NSString *);
typedef void (^FaileBlock)(NSError *);


@interface MFDownLoadManager ()<NSURLSessionDataDelegate>

@property(nonatomic, copy) ProgressBlock progressBlock;
@property(nonatomic, copy) SuccssBlock succssBlock;
@property(nonatomic, copy) FaileBlock faileBlock;


/**
 session
 */
@property(nonatomic, strong) NSURLSession *session;

/**
 下载任务
 */
@property(nonatomic, strong) NSURLSessionDataTask *task;


/**
 请求url
 */
@property(nonatomic, copy) NSString *downLoadUrl;
/**
 下载数据的总长度
 */
@property(nonatomic, assign) NSInteger totalLength;

/**
 写文件，它是要将已存在的内存(buffer)里的数据写入文件
 */
@property(nonatomic, strong) NSOutputStream *stream;

@end

@implementation MFDownLoadManager

+ (__kindof MFDownLoadManager *)sharedInstance{
    
    
    static MFDownLoadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)downLoad:(NSString *)url
    saveFilePath:(NSString *)filePath
        progress:(void(^)(NSString *))progressBlock
         success:(void(^)(NSString *))succssBlock
           faile:(void(^)(NSError *))faileBlock{
    
    self.progressBlock = progressBlock;
    self.succssBlock = succssBlock;
    self.faileBlock = faileBlock;
    self.downLoadUrl = url;
    [self.task resume];
}

-(void)suspendTask{
    [self.task suspend ];
}


#pragma mark - =========NSURLSessionDataDelegate =========
/**
 请求响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSHTTPURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;
{
    //打开stream
    [self.stream open];
    
    /*
     （Content-Length字段返回的是服务器对每次客户端请求要下载文件的大小）
     比如首次客户端请求下载文件A，大小为1000byte，那么第一次服务器返回的Content-Length = 1000，
     客户端下载到500byte，突然中断，再次请求的range为 “bytes=500-”，那么此时服务器返回的Content-Length为500
     所以对于单个文件进行多次下载的情况（断点续传），计算文件的总大小，必须把服务器返回的content-length加上本地存储的已经下载的文件大小
     */
    
   
    //计算下载数据的总长度 = 本次请求的数据长度+已经下载过的数据长度
    // 获取指定路径下文件的大小，iOS已经提供了相关的功能，实现代码如下， DownLoadDataLength
    self.totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + DownLoadDataLength;
    
    
    //把本次请求的长度存放到plist中
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:TotalLengthPlist];
    if (!dic) dic = [[NSMutableDictionary alloc] init];
    dic[@"FileName"] = @(self.totalLength);
    [dic writeToFile:TotalLengthPlist atomically:YES];
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}
/**
 请求数据 （多次调用）
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    
    //将接收到的数据通过写入流  存取数据到 指定路径
    [self.stream write:data.bytes maxLength:data.length];
    //已经下载过的数据长度
    NSLog(@"下载进度111:%f",1.0*DownLoadDataLength/self.totalLength);
    if (self.progressBlock) {
        self.progressBlock([NSString stringWithFormat:@"%f",1.0*DownLoadDataLength/self.totalLength]);
    }
    
}

/**
 请求完成
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    
    if (self.succssBlock) {
        self.succssBlock(DownLoadFilePath);
    }
    if (self.faileBlock) {
        self.faileBlock(error);
    }
    //关闭文件写入流
    [self.stream close];
    self.stream = nil;
    self.task = nil;
    
    
}
#pragma mark - =========懒加载 =========
- (NSURLSession *)session{
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}
- (NSURLSessionDataTask *)task{
    if (!_task) {
        //为了防止文件名重复 可以对url的fileName进行MD5加密
        // 文件名（沙盒中的文件名），使用md5哈希url生成的，这样就能保证文件名唯一
        //#define  Filename  self.downLoadUrl.md5String
       NSInteger totalLenth = [[NSDictionary dictionaryWithContentsOfFile:TotalLengthPlist][@"FileName"] integerValue];
        if (totalLenth && DownLoadDataLength == totalLenth) {
            NSLog(@"文件已经下载过");
            return nil;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.downLoadUrl]];
        // 设置请求头
        // Range : bytes=xxx-xxx
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-",DownLoadDataLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        _task = [self.session dataTaskWithRequest:request];
        
    }
    return _task;
}

- (NSOutputStream *)stream{
    if (!_stream) {
        _stream = [NSOutputStream outputStreamToFileAtPath:DownLoadFilePath append:YES];
    }
    return _stream;
}

@end
