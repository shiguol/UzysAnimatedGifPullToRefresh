//
//  UIScrollView+UzysAnimatedGifPullToRefresh.m
//  UzysAnimatedGifPullToRefresh
//
//  Created by Uzysjung on 2014. 4. 8..
//  Copyright (c) 2014년 Uzys. All rights reserved.
//

#import "UIScrollView+UzysAnimatedGifPullToRefresh.h"
#import <objc/runtime.h>
#import <AnimatedGIFImageSerialization.h>
#define IS_IOS7 (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
#define cDefaultFloatComparisonEpsilon    0.001
#define cEqualFloats(f1, f2, epsilon)    ( fabs( (f1) - (f2) ) < epsilon )
#define cNotEqualFloats(f1, f2, epsilon)    ( !cEqualFloats(f1, f2, epsilon) )

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (UzysAnimatedGifPullToRefresh)
@dynamic pullToRefreshView, showPullToRefresh;

- (void)addPullToRefreshActionHandler:(actionHandler)handler
                       ProgressImages:(NSArray *)progressImages
                        LoadingImages:(NSArray *)loadingImages
              ProgressScrollThreshold:(NSInteger)threshold
               LoadingImagesFrameRate:(NSInteger)lframe;
{
    if(self.pullToRefreshView == nil)
    {
        UzysAnimatedGifActivityIndicator *view = [[UzysAnimatedGifActivityIndicator alloc] initWithProgressImages:progressImages LoadingImages:loadingImages ProgressScrollThreshold:threshold LoadingImagesFrameRate:lframe];
        view.pullToRefreshHandler = handler;
        view.scrollView = self;
        view.frame = CGRectMake((self.bounds.size.width - view.bounds.size.width)/2,
                                -view.bounds.size.height, view.bounds.size.width, view.bounds.size.height);
        view.originalTopInset = self.contentInset.top;
        
        if(IS_IOS7)
        {
            if(cEqualFloats(self.contentInset.top, 64.00, cDefaultFloatComparisonEpsilon) && cEqualFloats(self.frame.origin.y, 0.0, cDefaultFloatComparisonEpsilon))
            {
                view.portraitTopInset = 64.0;
                view.landscapeTopInset = 52.0;
            }
        }

        [self addSubview:view];
        [self sendSubviewToBack:view];
        self.pullToRefreshView = view;
        self.showPullToRefresh = YES;
    }
    
}

- (void)addPullToRefreshActionHandler:(actionHandler)handler
                       ProgressImages:(NSArray *)progressImages
              ProgressScrollThreshold:(NSInteger)threshold
{
    [self addPullToRefreshActionHandler:handler
                         ProgressImages:progressImages
                          LoadingImages:nil
                ProgressScrollThreshold:threshold
                 LoadingImagesFrameRate:0];
}

- (void)addPullToRefreshActionHandler:(actionHandler)handler ProgressImagesGifName:(NSString *)progressGifName LoadingImagesGifName:(NSString *)loadingGifName ProgressScrollThreshold:(NSInteger)threshold
{
    UIImage *progressImage = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath]  stringByAppendingPathComponent:progressGifName]];
    UIImage *loadingImage = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath]  stringByAppendingPathComponent:loadingGifName]];
    
    [self addPullToRefreshActionHandler:handler
                         ProgressImages:progressImage.images
                          LoadingImages:loadingImage.images
                ProgressScrollThreshold:threshold
                 LoadingImagesFrameRate:(NSInteger)ceilf(1.0/(loadingImage.duration/loadingImage.images.count))];
}
- (void)addPullToRefreshActionHandler:(actionHandler)handler ProgressImagesGifName:(NSString *)progressGifName LoadingImagesGifName:(NSString *)loadingGifName ProgressScrollThreshold:(NSInteger)threshold LoadingImageFrameRate:(NSInteger)frameRate
{
    UIImage *progressImage = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath]  stringByAppendingPathComponent:progressGifName]];
    UIImage *loadingImage = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath]  stringByAppendingPathComponent:loadingGifName]];
    
    [self addPullToRefreshActionHandler:handler
                         ProgressImages:progressImage.images
                          LoadingImages:loadingImage.images
                ProgressScrollThreshold:threshold
                 LoadingImagesFrameRate:frameRate];
}
- (void)addPullToRefreshActionHandler:(actionHandler)handler ProgressImagesGifName:(NSString *)progressGifName ProgressScrollThreshold:(NSInteger)threshold
{
    UIImage *progressImage = [[UIImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath]  stringByAppendingPathComponent:progressGifName]]; //[UIImage imageNamed:progressGifName];

    [self addPullToRefreshActionHandler:handler
                         ProgressImages:progressImage.images
                ProgressScrollThreshold:threshold];
}

- (void)addTopInsetInPortrait:(CGFloat)pInset TopInsetInLandscape:(CGFloat)lInset
{
    self.pullToRefreshView.portraitTopInset = pInset;
    self.pullToRefreshView.landscapeTopInset = lInset;
}

- (void)removePullToRefreshActionHandler
{
    self.showPullToRefresh = NO;
    [self.pullToRefreshView removeFromSuperview];
    self.pullToRefreshView = nil;
}
- (void)triggerPullToRefresh
{
    [self.pullToRefreshView manuallyTriggered];
}
- (void)stopRefreshAnimation
{
    [self.pullToRefreshView stopIndicatorAnimation];
}
#pragma mark - property
- (void)setPullToRefreshView:(UzysAnimatedGifActivityIndicator *)pullToRefreshView
{
    [self willChangeValueForKey:@"UzysAnimatedGifActivityIndicator"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView, pullToRefreshView, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"UzysAnimatedGifActivityIndicator"];
}
- (UzysAnimatedGifActivityIndicator *)pullToRefreshView
{
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowPullToRefresh:(BOOL)showPullToRefresh {
    self.pullToRefreshView.hidden = !showPullToRefresh;
    
    if(showPullToRefresh)
    {
        if(!self.pullToRefreshView.isObserving)
        {
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification
             object:[UIDevice currentDevice]];
            
            self.pullToRefreshView.isObserving = YES;
        }
    }
    else
    {
        if(self.pullToRefreshView.isObserving)
        {
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
            [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
            
            self.pullToRefreshView.isObserving = NO;
        }
    }
}

- (BOOL)showPullToRefresh
{
    return !self.pullToRefreshView.hidden;
}

- (void)setShowAlphaTransition:(BOOL)showAlphaTransition
{
    self.pullToRefreshView.showAlphaTransition = showAlphaTransition;
}
- (BOOL)showAlphaTransition
{
    return self.pullToRefreshView.showAlphaTransition;
}
- (void)setShowVariableSize:(BOOL)showVariableSize
{
    self.pullToRefreshView.isVariableSize = showVariableSize;
}
-(BOOL)showVariableSize
{
    return self.pullToRefreshView.isVariableSize;
}
- (void)setActivityIndcatorStyle:(UIActivityIndicatorViewStyle)activityIndcatorStyle
{
    [self.pullToRefreshView setActivityIndicatorViewStyle:activityIndcatorStyle];
}
- (UIActivityIndicatorViewStyle)activityIndcatorStyle
{
    return self.pullToRefreshView.activityIndicatorStyle;
}
- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(UIDeviceOrientationIsLandscape(device.orientation))
        {
            if(cNotEqualFloats( self.pullToRefreshView.landscapeTopInset , 0.0 , cDefaultFloatComparisonEpsilon))
                self.pullToRefreshView.originalTopInset = self.pullToRefreshView.landscapeTopInset;
        }
        else
        {
            if(cNotEqualFloats( self.pullToRefreshView.portraitTopInset , 0.0 , cDefaultFloatComparisonEpsilon))
                self.pullToRefreshView.originalTopInset = self.pullToRefreshView.portraitTopInset;
        }
        if(self.pullToRefreshView.state == UZYSGIFPullToRefreshStateLoading && self.pullToRefreshView.isVariableSize)
        {
            [self.pullToRefreshView setFrameSizeByLoadingImage];
        }
        else
        {
            [self.pullToRefreshView setFrameSizeByProgressImage];
        }
    });
}


@end
