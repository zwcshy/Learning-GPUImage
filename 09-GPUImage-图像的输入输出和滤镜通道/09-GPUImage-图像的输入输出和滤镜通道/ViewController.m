//
//  ViewController.m
//  09-GPUImage-图像的输入输出和滤镜通道
//
//  Created by 黄进文 on 16/9/20.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController () {
    
    GPUImageVideoCamera *jVideoCamera;
}

@property (nonatomic, strong) UILabel *jLabel;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) GPUImageRawDataOutput *jOutput;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPUImageView *jImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.view = jImageView;
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    // 垂直翻转
    self.imageView.transform = CGAffineTransformScale(self.imageView.transform, -1.0, 1.0);
    // 水平翻转
    // self.imageView.transform = CGAffineTransformScale(self.imageView.transform, 1.0, -1.0);
    [self.view addSubview:self.imageView];
    
    self.jLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 120, 100)];
    self.jLabel.textColor = [UIColor orangeColor];
    [self.view addSubview:self.jLabel];
    
    // 设置摄像头
    jVideoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    jVideoCamera.outputImageOrientation = UIDeviceOrientationPortrait;
    jVideoCamera.horizontallyMirrorRearFacingCamera = YES;
    self.jOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(720.0, 1280.0) resultsInBGRAFormat:YES];
    
    [jVideoCamera addTarget:self.jOutput];
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(self.jOutput) weakOutput = self.jOutput;
    [self.jOutput setNewFrameAvailableBlock:^{
        
        __strong GPUImageRawDataOutput *strongOutput = weakOutput;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongOutput lockFramebufferForReading]; // 加锁
        GLubyte *outputBytes = [strongOutput rawBytesForImage];
        NSInteger bytesPerRow = [strongOutput bytesPerRowInOutput];
        CVPixelBufferRef pixelBuffer = NULL;
        CVReturn ret = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, 1280, 720, kCVPixelFormatType_32BGRA, outputBytes, bytesPerRow, nil, nil, nil, &pixelBuffer);
        if (ret != kCVReturnSuccess) {
            
            NSLog(@"status %d", ret);
        }
        
        [strongOutput unlockFramebufferAfterReading]; // 解锁
        
        if (pixelBuffer == NULL) {
            
            return;
        }
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, strongOutput.rawBytesForImage, bytesPerRow * 1280, NULL);
        CGImageRef cgImage = CGImageCreate(720, 1280, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little, provider, NULL, true, kCGRenderingIntentDefault);
        
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        [strongSelf updateWithImage:image];
        CGImageRelease(cgImage);
        CFRelease(pixelBuffer);
    }];
    
    [jVideoCamera startCameraCapture];
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [displayLink setPaused:NO];
}

- (void)updateProgress:(CADisplayLink *)link {
    
    self.jLabel.text = [[NSDate dateWithTimeIntervalSinceNow:0] description];
    [self.jLabel sizeToFit];
}

- (void)updateWithImage:(UIImage *)image {
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        self.imageView.image = image;
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

























