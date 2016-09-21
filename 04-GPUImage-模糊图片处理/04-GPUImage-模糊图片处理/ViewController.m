//
//  ViewController.m
//  04-GPUImage-模糊图片处理
//
//  Created by 黄进文 on 16/9/19.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"

@interface ViewController ()

@property (nonatomic, strong) GPUImagePicture *jSourcePicture;

@property (nonatomic, strong) GPUImageTiltShiftFilter *jShiftFilter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPUImageView *primaryImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:primaryImageView];
    
    UIImage *image = [UIImage imageNamed:@"love.jpg"];
    self.jSourcePicture = [[GPUImagePicture alloc] initWithImage:image]; // 图片源
    
    self.jShiftFilter = [[GPUImageTiltShiftFilter alloc] init];
    self.jShiftFilter.blurRadiusInPixels = 40.0; // 模糊处理
    [self.jShiftFilter forceProcessingAtSize:primaryImageView.sizeInPixels]; // 设置图片模糊范围
    
    [self.jSourcePicture addTarget:self.jShiftFilter]; // 添加模糊
    [self.jShiftFilter addTarget:primaryImageView]; // 显示图片
    [self.jSourcePicture processImage]; // 处理图像
    
    GLint size   = [GPUImageContext maximumTextureSizeForThisDevice];
    GLint unit   = [GPUImageContext maximumTextureUnitsForThisDevice];
    GLint vector = [GPUImageContext maximumVaryingVectorsForThisDevice];
    
    NSLog(@"size = %d, unit = %d, vector = %d", size, unit, vector);
}

// 图片处理很慢
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view]; // 获取点击区域点
    float rate = point.y / self.view.frame.size.height;
    NSLog(@"processing 处理图片");
    
    [self.jShiftFilter setTopFocusLevel:rate - 0.1];
    [self.jShiftFilter setBottomFocusLevel:rate + 0.1];
    [self.jSourcePicture processImage];
}


@end






























