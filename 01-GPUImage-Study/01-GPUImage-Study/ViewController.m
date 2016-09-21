//
//  ViewController.m
//  01-GPUImage-Study
//
//  Created by 黄进文 on 16/9/18.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@property (nonatomic, strong) UIImageView *gImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    self.gImageView = imageView;
    [self setupGPUImage];
}

- (void)setupGPUImage {
    
    UIImage *image = [UIImage imageNamed:@"love"];
    [self.gImageView setImage:[self applyImageGaussianSelectiveBlurFilter:image]];
    // iOS 8.0 添加设置模糊属性
    // UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    // UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    // effectView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    // [self.view addSubview:effectView];
}

#pragma 图片颜色调整
/**
 *  褐色 怀旧
 */
- (UIImage *)applyImageSepiaFilter:(UIImage *)image {
    
    GPUImageSepiaFilter *filter = [[GPUImageSepiaFilter alloc] init];
    [filter forceProcessingAtSize:image.size];
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    [picture addTarget:filter];
    [picture processImage];
    [filter useNextFrameForImageCapture];
    return [filter imageFromCurrentFramebuffer];
    // return [filter imageByFilteringImage:image];
}

/**
 *  反色
 */
- (UIImage *)applyImageColorInvertFilter:(UIImage *)image {
    
    GPUImageColorInvertFilter *filter = [[GPUImageColorInvertFilter alloc] init];
    [filter forceProcessingAtSize:image.size];
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    [picture addTarget:filter];
    [picture processImage];
    [filter useNextFrameForImageCapture];
    return [filter imageFromCurrentFramebuffer];
}

/**
 *  色彩直方图
 */
- (UIImage *)applyImageHistogramGenerator:(UIImage *)image {
    
    GPUImageHistogramGenerator *filter = [[GPUImageHistogramGenerator alloc] init];
    [filter forceProcessingAtSize:image.size];
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    [picture addTarget:filter];
    [picture processImage];
    [filter useNextFrameForImageCapture];
    return [filter imageFromCurrentFramebuffer];
}

/**
 *  素描
 */
- (UIImage *)applyImageSketchFilter:(UIImage *)image {
    
    GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
    // 过滤强度属性影响滤波器的动态范围。高值可以使边缘更加明显,但会导致饱和。默认为1.0。
    filter.edgeStrength = 0.5;
    [filter forceProcessingAtSize:image.size];
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    [picture addTarget:filter];
    [picture processImage];
    [filter useNextFrameForImageCapture];
    return [filter imageFromCurrentFramebuffer];
}

/**
 *  高斯模糊 全局模糊
 *  texelSpacingMultiplier是模糊的强度，数值越大，模糊效果越明显
 *  blurRadiusInPixels是像素范围，用于计算平均值
 */
- (UIImage *)applyImageGaussianBlurFilter:(UIImage *)image {
    
    GPUImageGaussianBlurFilter *filter = [[GPUImageGaussianBlurFilter alloc] init];
    filter.texelSpacingMultiplier = 3.0; // 数值越大，模糊效果越明显
    filter.blurRadiusInPixels = 5.0; // 用于计算平均值
    [filter forceProcessingAtSize:image.size];
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    [picture addTarget:filter];
    [picture processImage];
    [filter useNextFrameForImageCapture];
    return [filter imageFromCurrentFramebuffer];
}

/**
 *  局部模糊
 *  GPUImageGaussianSelectiveBlurFilter 可以部分模糊，也就是选区外模糊
 *  excludeCircleRadius 用来调整模糊区域
 */
- (UIImage *)applyImageGaussianSelectiveBlurFilter:(UIImage *)image {
    
    GPUImageGaussianSelectiveBlurFilter *filter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
    filter.excludeCircleRadius = 120 / 320.0;
    [filter forceProcessingAtSize:image.size];
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    [picture addTarget:filter];
    [picture processImage];
    [filter useNextFrameForImageCapture];
    return [filter imageFromCurrentFramebuffer];
}

@end
















































