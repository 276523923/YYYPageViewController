//
//  YYYPageViewController.h
//  YYYPageViewController
//
//  Created by 叶越悦 on 2018/6/3.
//  Copyright © 2018年. All rights reserved.
//

#import <UIKit/UIKit.h>
@class YYYPageViewController;
@protocol YYYPageViewControllerDataSource <NSObject>

- (NSInteger)numberOfControllersInPageViewController:(YYYPageViewController *)pageViewController;
- (__kindof UIViewController *)pageViewController:(YYYPageViewController *)pageViewController viewControllerAtIndex:(NSInteger)index;

@end

@protocol YYYPageViewControllerDelegate <NSObject>

@optional
- (void)pageViewController:(YYYPageViewController *)pageViewController didScroll:(UIScrollView *)scrollView;
- (void)pageViewController:(YYYPageViewController *)pageViewController didScrollToIndex:(NSInteger)index;


@end

@interface YYYPageViewController : UIViewController

@property (nonatomic, weak) id<YYYPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<YYYPageViewControllerDelegate> delegate;
@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, weak, readonly) UIViewController *currentViewController;

/**
 pageViewController disAppear 后，过 autoReleaseCacheControllerTime 时间后会释放掉缓存的childViewController
 currentViewController 不会释放
 默认10秒
 设置为 <= 0 的话，就不会自动释放。
 
 */
@property (nonatomic) CGFloat autoReleaseCacheControllerTime;

- (NSInteger)numberOfControllers;
- (UIViewController *)viewControllerAtIndex:(NSInteger)index;
- (void)showViewControllerAtIndex:(NSInteger)index;
- (void)reloadData;

@end
