//
//  GPUImageBeautifyFilter.h
//  03-GPUImage-实时美颜滤镜
//
//  Created by 黄进文 on 16/9/19.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "GPUImage.h"

@class GPUImageCombinationFilter;

@interface GPUImageBeautifyFilter : GPUImageFilterGroup {
    
    GPUImageBilateralFilter          *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageHSBFilter                *hsbFilter;
    GPUImageCombinationFilter        *combinationFilter;
}
    
/**
 *  A normalization factor for the distance between central color and sample color
 *
 *  @param value default 2.0
 */
- (void)setDistanceNormalizationFactor:(CGFloat)value;
    
/**
 *  Set brightness and saturation
 *
 *  @param brightness [0.0, 2.0], default 1.05
 *  @param saturation [0.0, 2.0], default 1.05
 */
- (void)setBrightness:(CGFloat)brightness saturation:(CGFloat)saturation;
    
@end
