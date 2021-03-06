//
//  FYBarCodeView.m
//  CreditCat
//
//  Created by 范杨 on 2018/1/24.
//  Copyright © 2018年 luming. All rights reserved.
//

#import "FYBarCodeView.h"

@interface FYBarCodeView()
/**
 背景view,解决动画完成后view点击无法返回的问题
 */
@property (strong, nonatomic) UIView *bgView;

/**
 条形码
 */
@property (strong, nonatomic) UIImageView *barCodeImageView;

/**
 当前控制器
 */
@property (strong, nonatomic) UIViewController *currentVC;

/**
 手势触发view
 */
@property (strong, nonatomic) UIView *clearTapView;
@end
@implementation FYBarCodeView

#pragma mark - public
- (instancetype)initWithBarCodeStr:(NSString *)barCodeStr frame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {

        CGRect barCodeViewFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - 19);
        UIImageView *codeImageView = [UIImageView new];
        codeImageView.userInteractionEnabled = YES;
        [self addSubview:codeImageView];
        codeImageView.image = [self barcodeImageWithContent:barCodeStr codeImageSize:barCodeViewFrame.size red:0/255.f green:0/255.f blue:0/255.f];
        self.barCodeImageView = codeImageView;
        [codeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(@0);
            make.height.equalTo(@(barCodeViewFrame.size.height));
        }];
        
        UILabel *barCodeStrLabel = [[UILabel alloc] init];
        [self addSubview:barCodeStrLabel];
        [barCodeStrLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(codeImageView.mas_centerX);
            make.top.equalTo(codeImageView.mas_bottom).offset(5);
        }];
        barCodeStrLabel.text = [self p_formaterBarCodeStr:barCodeStr];
        barCodeStrLabel.font = [UIFont systemFontOfSize:14];
        barCodeStrLabel.textColor = [UIColor colorWithHexString:@"333333"];
        //改变字间距
        if (barCodeStr.length > 0) {
            [UILabel changeWordSpaceForLabel:barCodeStrLabel WithSpace:2];
        }
    }
    return self;
}

- (void)startRotation{
    
    UIViewController *currentVC = [self p_getCurrentController];
    self.currentVC = currentVC;
    [currentVC.view addSubview:self.bgView];
    [self.bgView insertSubview:self belowSubview:self.bgView];
    [[UIApplication sharedApplication].keyWindow addSubview:self.clearTapView];
    [self p_viewRotationAnimationWithNeedRotation:YES rotationView:self];
}

- (void)finishRotation{
    
    [self p_viewRotationAnimationWithNeedRotation:NO rotationView:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.bgView removeFromSuperview];
        [self.clearTapView removeFromSuperview];
        [self.currentVC.view addSubview:self];
        self.bgView = nil;
        self.currentVC = nil;
        self.clearTapView = nil;
    });
}

#pragma mark - private
- (NSString *)p_formaterBarCodeStr:(NSString *)barCodeStr{
    
    if (barCodeStr.length != 18) {
        return barCodeStr;
    }
    
    NSString * firstStr = [barCodeStr substringToIndex:4];
    NSString * secondStr= [barCodeStr substringWithRange:NSMakeRange(4, 4)];
    NSString * thirdStr = [barCodeStr substringWithRange:NSMakeRange(8, 4)];
    NSString * forthStr = [barCodeStr substringWithRange:NSMakeRange(12, 6)];

    return [NSString stringWithFormat:@"%@  %@  %@  %@",firstStr,secondStr,thirdStr,forthStr];

}
- (UIViewController *)p_getCurrentController{
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}
- (void)p_viewRotationAnimationWithNeedRotation:(BOOL)isNeedRotation rotationView:(UIView *)rotationView{
    
    if (isNeedRotation && self.fyBarCodeDelegate && [self.fyBarCodeDelegate respondsToSelector:@selector(barCodeViewStartRotationWithView:)]) {
        [self.fyBarCodeDelegate barCodeViewStartRotationWithView:self];
    }
    
    if (!isNeedRotation && self.fyBarCodeDelegate && [self.fyBarCodeDelegate respondsToSelector:@selector(barCodeViewFinishRotationWithView:)]) {
        [self.fyBarCodeDelegate barCodeViewFinishRotationWithView:self];
    }
    
    CGPoint oldCenterPoint = rotationView.center;
    CGPoint newCenterPoint = CGPointMake(ScreenWidth/2, ScreenHeight/2);
    
    //旋转
    CABasicAnimation* rotationAnimation1 = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation1.fromValue = [NSNumber numberWithFloat:isNeedRotation?0 : M_PI_2];
    rotationAnimation1.toValue = [NSNumber numberWithFloat:isNeedRotation? M_PI_2 :0 ];
    
    //缩放
    CABasicAnimation* rotationAnimation2= [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    CGFloat scaleNumber;
    if (IS_STANDARD_IPHONE_6) {
        scaleNumber = 1.94;
    }else if (IS_STANDARD_IPHONE_6_PLUS){
        scaleNumber = 2.08;
    }else{
        scaleNumber = 1.87;
    }
    rotationAnimation2.fromValue = [NSNumber numberWithFloat:isNeedRotation? 1.0:scaleNumber];
    rotationAnimation2.toValue = [NSNumber numberWithFloat:isNeedRotation? scaleNumber:1.0];
    
    //中心位移
    CABasicAnimation *rotationAnimation3 =
    [CABasicAnimation animationWithKeyPath:@"position"];
    rotationAnimation3.fromValue = [NSValue valueWithCGPoint:isNeedRotation?oldCenterPoint:newCenterPoint ];
    rotationAnimation3.toValue = [NSValue valueWithCGPoint: isNeedRotation?newCenterPoint:oldCenterPoint ]; // 終点
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    // 动画选项设定
    group.duration = 0.3;
    group.repeatCount = 1;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    group.animations = [NSArray arrayWithObjects:rotationAnimation1,rotationAnimation2,rotationAnimation3,nil];
    [rotationView.layer addAnimation:group forKey:@"move-rotate-layer"];
}

/**
 生成二维码
 */
- (UIImage *)barcodeImageWithContent:(NSString *)content codeImageSize:(CGSize)size red:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue{
    UIImage *image = [self barcodeImageWithContent:content codeImageSize:size];
    int imageWidth = image.size.width;
    int imageHeight = image.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t *rgbImageBuf = (uint32_t *)malloc(bytesPerRow * imageHeight);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpaceRef, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    //遍历像素, 改变像素点颜色
    int pixelNum = imageWidth * imageHeight;
    uint32_t *pCurPtr = rgbImageBuf;
    for (int i = 0; i<pixelNum; i++, pCurPtr++) {
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900) {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = red*255;
            ptr[2] = green*255;
            ptr[1] = blue*255;
        }else{
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
    }
    //取出图片
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpaceRef,
                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    
    return resultImage;
}

//改变条形码尺寸大小
- (UIImage *)barcodeImageWithContent:(NSString *)content codeImageSize:(CGSize)size{
    CIImage *image = [self barcodeImageWithContent:content];
    CGRect integralRect = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size.width/CGRectGetWidth(integralRect), size.height/CGRectGetHeight(integralRect));
    
    size_t width = CGRectGetWidth(integralRect)*scale;
    size_t height = CGRectGetHeight(integralRect)*scale;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpaceRef, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:integralRect];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, integralRect, bitmapImage);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

//生成最原始的条形码
- (CIImage *)barcodeImageWithContent:(NSString *)content{
    CIFilter *qrFilter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
    [qrFilter setValue:contentData forKey:@"inputMessage"];
    [qrFilter setValue:@(0.00) forKey:@"inputQuietSpace"];
    CIImage *image = qrFilter.outputImage;
    return image;
}

void ProviderReleaseData (void *info, const void *data, size_t size){
    free((void*)data);
}

#pragma mark - set && get
- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
        _bgView.backgroundColor = [UIColor whiteColor];
    }
    return _bgView;
}
- (UIView *)clearTapView{
    if (!_clearTapView) {
        _clearTapView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
        _clearTapView.backgroundColor = [UIColor clearColor];
        @weakify(self);
        [_clearTapView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
            @strongify(self);
            [self finishRotation];
        }];
    }
    return _clearTapView;
}
@end
