//
//  ViewController.m
//  断点下载
//
//  Created by 大虾咪 on 2017/9/7.
//  Copyright © 2017年 大虾咪. All rights reserved.
//

#import "ViewController.h"
#import "MFDownLoadManager.h"

@interface ViewController ()


@end

@implementation ViewController


- (IBAction)start:(UIButton *)sender {
    
    
    [[MFDownLoadManager sharedInstance] downLoad:@"http://127.0.0.1/text.flv" saveFilePath:@"" progress:^(NSString *progress) {
        NSLog(@"下载进度======%@",progress);
        
    } success:^(NSString *filePath) {
        
        //下载成功之后存放的位置
        
    } faile:^(NSError *error) {
        
        //下载失败
        
    }];
    
}
- (IBAction)spause:(id)sender {
    
    [[MFDownLoadManager sharedInstance] suspendTask];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
   
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
