//
//  ViewController.m
//  05-GPUImage-滤镜视频录制
//
//  Created by 黄进文 on 16/9/19.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "GPUImageBeautifyFilter.h"

#define SCREENWIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREENHEIGHT [[UIScreen mainScreen] bounds].size.height

@interface ViewController ()

@property (nonatomic, strong) GPUImageVideoCamera *jVideoCamera;

@property (nonatomic, strong) GPUImageMovieWriter *jMovieWriter;

@property (nonatomic, strong) GPUImageView *jImageView;

@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;

@property (nonatomic, strong) UIButton *jButton;

@property (nonatomic, strong) UILabel *jTimeLabel;

@property (nonatomic, assign) long jTime;

@property (nonatomic, strong) NSTimer *jTimer;

@property (nonatomic, strong) CADisplayLink *jDisplayLink;

@property (nonatomic, strong) UISlider *jSlider;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 摄像
    self.jVideoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    self.jVideoCamera.outputImageOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 滤镜 褐色
    self.filter = [[GPUImageBeautifyFilter alloc] init];
    // 显示图像
    self.jImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.view = self.jImageView;
    
    // 初始化基本控件
    [self setupControls];
    
    [self.jVideoCamera addTarget:self.filter]; // 添加滤镜
    [self.filter addTarget:self.jImageView]; // 图像来源
    [self.jVideoCamera startCameraCapture]; // 开始录制
    
    self.jDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLink:)];
    [self.jDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

#pragma mark - CADisplayLink
- (void)displayLink:(CADisplayLink *)displayLink {
    
    NSLog(@"%f", displayLink.timestamp);
}

#pragma mark - slider addTarget的方法
// 改变滤镜
- (void)updateSliderValue:(UISlider *)slider {
    
    //[(GPUImageBeautifyFilter *)self.filter setDistanceNormalizationFactor:[slider value]];
    //[(GPUImageBeautifyFilter *)self.filter setBrightness:[slider value] saturation:[slider value]];
}

#pragma mark - button
- (void)jButtonOnClick:(UIButton *)button {
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"movie.m4v"];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    if ([button.currentTitle isEqualToString:@"录制"]) {
        
        [button setTitle:@"结束" forState:UIControlStateNormal];
        NSLog(@"开始录制视频");
        unlink([filePath UTF8String]); // 如果已经存在文件，AVAssetWriter会有异常，删除旧文件
        self.jMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:fileUrl size:CGSizeMake(720.0, 1280.0)];
        self.jMovieWriter.encodingLiveVideo = YES; // 实时录制
        [self.filter addTarget:self.jMovieWriter];
        self.jVideoCamera.audioEncodingTarget = self.jMovieWriter;
        [self.jMovieWriter startRecording]; // 开始录制
        
        _jTime = 0;
        self.jTimeLabel.hidden = NO;
        [self onTimer:nil];
        self.jTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES]; // 1s 重复
    }
    else {
        
        [button setTitle:@"录制" forState:UIControlStateNormal];
        NSLog(@"录制结束");
        self.jTimeLabel.hidden = YES;
        if (self.jTimer) {
            
            [self.jTimer invalidate];
        }
        [self.filter removeTarget:self.jMovieWriter];
        self.jVideoCamera.audioEncodingTarget = nil;
        [self.jMovieWriter finishRecording];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
            
            [library writeVideoAtPathToSavedPhotosAlbum:fileUrl completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil];
                        [alert show];
                    });
                }
                else {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil];
                        [alert show];
                    });
                }
                
            }];
        }
    }
}

- (void)onTimer:(nullable id)sender {
    
    self.jTimeLabel.text = [NSString stringWithFormat:@"%ld s", self.jTime++];
    [self.jTimeLabel sizeToFit];
}

#pragma mark - 初始化控件
- (void)setupControls {
    
    CGFloat valueWH = 64;
    
    self.jButton = [[UIButton alloc] initWithFrame:CGRectMake((SCREENWIDTH - valueWH) * 0.5, SCREENHEIGHT - 1.5 * valueWH, valueWH, valueWH)];
    self.jButton.layer.cornerRadius = valueWH * 0.5;
    self.jButton.layer.masksToBounds = YES;
    self.jButton.backgroundColor = [UIColor lightGrayColor];
    [self.jButton setTitle:@"录制" forState:UIControlStateNormal];
    [self.jButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.jButton addTarget:self action:@selector(jButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.jButton];
    
    self.jTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREENWIDTH * 0.5, SCREENHEIGHT * 0.5, 50, 50)];
    self.jTimeLabel.textColor = [UIColor redColor];
    // self.jTimeLabel.text = @"14:20";
    self.jTimeLabel.hidden = YES;
    [self.view addSubview:self.jTimeLabel];
    
    self.jSlider = [[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.jButton.frame) + 10, SCREENHEIGHT - 1.4 * valueWH, (SCREENWIDTH - valueWH) * 0.5 - 20, 40)];
    [self.jSlider addTarget:self action:@selector(updateSliderValue:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.jSlider];
}

@end









































