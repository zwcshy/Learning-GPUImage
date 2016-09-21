//
//  ViewController.m
//  06-GPUImage-视频水印
//
//  Created by 黄进文 on 16/9/20.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController () {
    
    GPUImageVideoCamera *jVideoCamera;
    GPUImageOutput<GPUImageInput> *jFilter;
    GPUImageMovieWriter *jMovieWriter;
    GPUImageMovie *jMovie;
}

@property (nonatomic, strong) UILabel *jLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPUImageView *jImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.view = jImageView; // 强引用
    
    self.jLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 120, 45)];
    self.jLabel.textColor = [UIColor orangeColor];
    self.jLabel.text = @"ddddd";
    [self.view addSubview:self.jLabel];
    
    jFilter = [[GPUImageDissolveBlendFilter alloc] init];
    [(GPUImageDissolveBlendFilter *)jFilter setMix:0.5];
    
    // 获取视频来源
    NSURL *movieURL = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@".m4v"];
    jMovie = [[GPUImageMovie alloc] initWithURL:movieURL];
    jMovie.runBenchmark = YES; // 注销了瞬时和平均帧时间到控制台
    jMovie.playAtActualSpeed = YES; // 这个决定播放电影一样快的帧可以被处理,或者电影的原始速度应该是一样的
    
    // 摄像头获取视频源
    jVideoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    jVideoCamera.outputImageOrientation = [UIApplication sharedApplication].statusBarOrientation; // 竖直
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"video.m4v"]; // 保存视频路径
    unlink([filePath UTF8String]);
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    // 将摄像头获取到的视频存在沙盒中
    jMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:fileURL size:CGSizeMake(720.0, 1280.0)];
    
    BOOL audioFromFile = NO;
    if (audioFromFile) {
        
        // 响应链
        [jMovie addTarget:jFilter];
        [jVideoCamera addTarget:jFilter];
        jMovieWriter.shouldPassthroughAudio = YES; // 表示是否使用源音源
        jMovie.audioEncodingTarget = jMovieWriter; // 表示音频来源是文件
        [jMovie enableSynchronizedEncodingUsingMovieWriter:jMovieWriter];
    }
    else {
        
        // 响应链
        [jVideoCamera addTarget:jFilter];
        [jMovie addTarget:jFilter];
        jMovieWriter.shouldPassthroughAudio = NO;
        jVideoCamera.audioEncodingTarget = jMovieWriter;
        jMovieWriter.encodingLiveVideo = NO;
    }
    
    // 显示到界面
    [jFilter addTarget:jImageView];
    [jFilter addTarget:jMovieWriter];
    [jVideoCamera startCameraCapture]; // 摄像头开始
    [jMovieWriter startRecording]; // 录制视频
    [jMovie startProcessing]; // 输出视频
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [displayLink setPaused:NO];
    
    __weak typeof(self) weakSelf = self;
    [jMovieWriter setCompletionBlock:^{
        
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->jFilter removeTarget:strongSelf->jMovieWriter];
        [strongSelf->jMovieWriter finishRecording];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
            
            // 保存视频
            [library writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    if (error) {
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存视频失败" message:nil delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
                        [alert show];
                    }
                    else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存视频成功" message:nil delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
                        [alert show];
                        
                    }
                });
            }];
        }
        else {
            NSLog(@"error msg)");
        }
    }];
    
}

- (void)updateProgress:(CADisplayLink *)link {
    
    self.jLabel.text = [NSString stringWithFormat:@"progress:%d%%", (int)(jMovie.progress * 100)];
    [self.jLabel sizeToFit];
}

@end




































