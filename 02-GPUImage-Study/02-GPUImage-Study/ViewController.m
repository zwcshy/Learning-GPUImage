//
//  ViewController.m
//  02-GPUImage-Study
//
//  Created by 黄进文 on 16/9/19.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) GPUImageView *gImageView;

@property (nonatomic, strong) GPUImageVideoCamera *gVideoCamera;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.gVideoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    self.gVideoCamera.outputImageOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.gImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    // kGPUImageFillModePreserveAspectRatio // 保持原宽高比，并且图像不超过屏幕。那么以当前屏幕大小为准
    // kGPUImageFillModePreserveAspectRatioAndFill // 保持原宽高比，并且图像要铺满整个屏幕。那么图像大小为准。
    self.gImageView.fillMode = kGPUImageFillModeStretch; // 图像拉伸，直接使宽高等于1.0即可，原图像会直接铺满整个屏幕
    [self.view addSubview:self.gImageView];
    // 美颜 变褐色
    GPUImageSepiaFilter *filter = [[GPUImageSepiaFilter alloc] init];
    [self.gVideoCamera addTarget:filter];
    [filter addTarget:self.gImageView];
    // 没有美颜
    // [self.gVideoCamera addTarget:self.gImageView];
    [self.gVideoCamera startCameraCapture];
}


@end














