//
//  ViewController.m
//  03-GPUImage-实时美颜滤镜
//
//  Created by 黄进文 on 16/9/19.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()

@property (nonatomic, strong) GPUImageVideoCamera *jVideoCamera;

@property (nonatomic, strong) GPUImageMovieWriter *jMovieWriter;

@property (nonatomic, strong) GPUImageView *jFilterImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化相机
    self.jVideoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    self.jVideoCamera.outputImageOrientation = UIInterfaceOrientationPortrait; // 屏幕竖立
    self.jVideoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    // 初始化GPUImageView
    self.jFilterImageView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.jFilterImageView.center = self.view.center;
    [self.view addSubview:self.jFilterImageView];
    
    NSString *moviePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"video.m4v"]; // 视频保存地址
    unlink([moviePath UTF8String]); // 如果已经存在文件，AVAssetWriter会有异常，删除旧文件
    NSURL *movieUrl = [NSURL fileURLWithPath:moviePath];
    self.jMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieUrl size:CGSizeMake(720.0, 1280.0)];
    self.jVideoCamera.audioEncodingTarget = self.jMovieWriter; // 音频编码
    self.jMovieWriter.encodingLiveVideo = YES; // 视频编码
    [self.jVideoCamera startCameraCapture]; // 打开摄像
    
    // 添加实时美颜滤镜
    GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.jVideoCamera addTarget:beautifyFilter];
    [beautifyFilter addTarget:self.jFilterImageView];
    [beautifyFilter addTarget:self.jMovieWriter];
    [self.jMovieWriter startRecording]; // 录视频
    
    // 保存视频10s的视频
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [beautifyFilter removeTarget:self.jMovieWriter];
        [self.jMovieWriter finishRecording];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath)) {
            
            [library writeVideoAtPathToSavedPhotosAlbum:movieUrl completionBlock:^(NSURL *assetURL, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    if (error) {
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
                        [alert show];
                    }
                    else {
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
                        [alert show];
                    }
                });
            }];
        }
        else {
            
            NSLog(@"error msg");
        }
    });
}


@end





































