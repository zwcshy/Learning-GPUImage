//
//  ViewController.m
//  07-GPUImage-文字水印和动态图像水印
//
//  Created by 黄进文 on 16/9/20.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController () {
    
    GPUImageMovie *jMovie;
    GPUImageOutput<GPUImageInput> *jFilter;
    GPUImageMovieWriter *jMovieWriter;
}

@property (nonatomic, strong) UILabel *jLabel;

@end

@implementation ViewController


/**
 响应链解析
 1、当GPUImageMovie的纹理就绪时，会通知GPUImageFilter处理图像；
 2、GPUImageFilter会调用frameProcessingCompletionBlock回调；
 3、GPUImageUIElement在回调中渲染图像，纹理就绪后通知
 GPUImageDissolveBlendFilter；
 4、frameProcessingCompletionBlock回调结束后，通知
 GPUImageDissolveBlendFilter纹理就绪；
 5、GPUImageDissolveBlendFilter收到两个纹理后开始渲染，纹理就绪后通知GPUImageMovieWriter；
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPUImageView *jImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.view = jImageView;
    
    self.jLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 120, 45)];
    self.jLabel.textColor = [UIColor orangeColor];
    [self.view addSubview:self.jLabel];
    
    // 滤镜
    jFilter = [[GPUImageDissolveBlendFilter alloc] init];
    [(GPUImageDissolveBlendFilter *)jFilter setMix:0.5];
    
    // 获取视频
    NSURL *movieURL = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@".m4v"];
    AVAsset *asset = [AVAsset assetWithURL:movieURL];
    jMovie = [[GPUImageMovie alloc] initWithAsset:asset];
    jMovie.runBenchmark = YES;
    jMovie.playAtActualSpeed = YES;
    
    // 文字/图片水印
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 120, 120, 45)];
    label.text = @"文字水印测试";
    label.font = [UIFont systemFontOfSize:24.0];
    label.textColor = [UIColor orangeColor];
    [label sizeToFit];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"love.png"]];
    imageView.center = self.view.center;
    
    UIView *subView = [[UIView alloc] initWithFrame:self.view.bounds];
    subView.backgroundColor = [UIColor clearColor];
    [subView addSubview:label];
    [subView addSubview:imageView];
    
    GPUImageUIElement *uiElement = [[GPUImageUIElement alloc] initWithView:subView];

    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"video.m4v"];
    unlink([filePath UTF8String]); // 删除旧文件
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    // 保存视频
    jMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:fileURL size:CGSizeMake(720.0, 1280.0)];
    
    GPUImageFilter *jImageFilter = [[GPUImageFilter alloc] init]; // 渲染纹理
    [jMovie addTarget:jImageFilter]; // 当GPUImageMovie的纹理就绪时，会通知GPUImageFilter处理图像；
    [jImageFilter addTarget:jFilter];
    [uiElement addTarget:jFilter];
    jMovieWriter.shouldPassthroughAudio = YES;
    jMovie.audioEncodingTarget = jMovieWriter;
    [jMovie enableSynchronizedEncodingUsingMovieWriter:jMovieWriter];
    
    // 显示到界面
    [jFilter addTarget:jImageView];
    [jFilter addTarget:jMovieWriter];
    [jMovieWriter startRecording];
    [jMovie startProcessing];
    
    CADisplayLink *displayerLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress:)];
    [displayerLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [displayerLink setPaused:NO];
    [jImageFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        
        CGRect frame = imageView.frame;
        frame.origin.x += 1;
        frame.origin.y += 1;
        imageView.frame = frame;
        [uiElement updateWithTimestamp:time];
    }];
    
    __weak typeof(self) weakSelf = self;
    [jMovieWriter setCompletionBlock:^{
        
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->jFilter removeTarget:strongSelf->jMovieWriter];
        [strongSelf->jMovieWriter finishRecording];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
            
            [library writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    }
                });
            }];
        }
        else {
            NSLog(@"error mssg)");
        }
    }];
    
}

- (void)updateProgress:(CADisplayLink *)link {
    
    self.jLabel.text = [NSString stringWithFormat:@"%d%%", (int)(jMovie.progress * 100)];
    [self.jLabel sizeToFit];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end











































