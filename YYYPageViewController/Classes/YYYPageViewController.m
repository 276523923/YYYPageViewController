//
//  YYYPageViewController.m
//  YYYPageViewController
//
//  Created by 叶越悦 on 2018/6/3.
//  Copyright © 2018年. All rights reserved.
//

#import "YYYPageViewController.h"
#import "YYYWeakProxy.h"

@interface YYYPageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic) NSInteger count;
@property (nonatomic, strong) NSMutableDictionary *controllersCache;
@property (nonatomic, weak, readwrite) UIViewController *currentViewController;
@property (nonatomic, weak) UIViewController *nextViewController;
@property (nonatomic, readwrite) NSInteger currentIndex;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation YYYPageViewController

#pragma mark - system
- (void)dealloc {
    [self releasetTimerIfNeed];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.autoReleaseCacheControllerTime = 10;
        _currentIndex = 0;
        _count = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadSubviews];
    [self reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self clearCacheControllerExceptCurrentViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.childViewControllers containsObject:self.currentViewController]) {
        [self.currentViewController beginAppearanceTransition:YES animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self releasetTimerIfNeed];
    if ([self.childViewControllers containsObject:self.currentViewController]) {
        [self.currentViewController endAppearanceTransition];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.childViewControllers containsObject:self.currentViewController]) {
        [self.currentViewController beginAppearanceTransition:NO animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.autoReleaseCacheControllerTime > 0) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.autoReleaseCacheControllerTime target:[YYYWeakProxy proxyWithTarget:self] selector:@selector(clearCacheControllerExceptCurrentViewController) userInfo:nil repeats:NO];
    }
    if ([self.childViewControllers containsObject:self.currentViewController]) {
        [self.currentViewController endAppearanceTransition];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!CGRectEqualToRect(_scrollView.frame, self.view.bounds)) {
        _scrollView.frame = self.view.bounds;
        CGSize size = _scrollView.frame.size;
        for (NSNumber *key in self.controllersCache.allKeys) {
            UIViewController *vc = self.controllersCache[key];
            if ([_scrollView.subviews containsObject:vc.view]) {
                vc.view.frame = CGRectMake(size.width * key.integerValue, 0, size.width, size.height);
            }
        }
    }
    
    if (_scrollView.contentSize.height != _scrollView.frame.size.height) {
        _scrollView.contentSize = CGSizeMake(self.count * _scrollView.frame.size.width, _scrollView.frame.size.height);
    }
    
    [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width * self.currentIndex, self.scrollView.contentOffset.y)];

    if (!UIEdgeInsetsEqualToEdgeInsets(_scrollView.contentInset, UIEdgeInsetsZero)) {
        [_scrollView setContentInset:UIEdgeInsetsZero];
    }
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.scrollView || !self.nextViewController || scrollView.isDragging) {
        return;
    }
    CGFloat offsetX = scrollView.contentOffset.x;
    NSInteger index = floor(offsetX/scrollView.frame.size.width);
    UIViewController *currentShowVC = [self viewControllerAtIndex:index];
    if (index == self.currentIndex) {
        [self.currentViewController beginAppearanceTransition:YES animated:YES];
        [self.nextViewController beginAppearanceTransition:NO animated:YES];
        [self.currentViewController endAppearanceTransition];
        [self.nextViewController endAppearanceTransition];
        [self yyy_removeChildViewController:self.nextViewController];
    } else {
        if (currentShowVC == self.nextViewController) {
            [self.nextViewController endAppearanceTransition];
            [self.currentViewController endAppearanceTransition];
        } else {
            [self.currentViewController endAppearanceTransition];
            [self.nextViewController beginAppearanceTransition:NO animated:YES];
            [self.nextViewController endAppearanceTransition];
            [currentShowVC beginAppearanceTransition:YES animated:YES];
            [currentShowVC endAppearanceTransition];
        }
        [self yyy_removeChildViewController:self.currentViewController];
    }
    _nextViewController = nil;
    self.currentIndex = index;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkSubViewControllerRemoveFromScrollView) object:nil];
    [self performSelector:@selector(checkSubViewControllerRemoveFromScrollView) withObject:nil afterDelay:1];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.scrollView) {
        return;
    }
    if (scrollView.isDragging) {
        CGFloat offsetX = scrollView.contentOffset.x;
        [self updateVisitViewControllerAtScrollView:scrollView];
        CGFloat width = CGRectGetWidth(scrollView.frame);
        CGFloat currentOffsetX = width * self.currentIndex;
        UIViewController *currentViewController = self.currentViewController;
        UIViewController *nextViewController = self.nextViewController;
        if (offsetX > currentOffsetX + width) {
            NSInteger index = floor(offsetX/width);
            UIViewController *currentVC = [self viewControllerAtIndex:index];
            if (currentVC == nextViewController) {
                [nextViewController endAppearanceTransition];//Did Appear
                [currentViewController endAppearanceTransition];//Did DisAppear
            } else {
                [currentViewController endAppearanceTransition];
                
                [nextViewController beginAppearanceTransition:NO animated:NO];
                [nextViewController endAppearanceTransition];
                [self yyy_removeChildViewController:nextViewController];//移除
                
                [currentVC beginAppearanceTransition:YES animated:YES];
                [currentVC endAppearanceTransition];
            }
            [self yyy_removeChildViewController:currentViewController];//移除
            self.currentIndex = index;
            _nextViewController = nil;
            currentOffsetX = width * self.currentIndex;
        } else if (offsetX < currentOffsetX - width) {
            
            NSInteger index = ceil(offsetX/width);
            UIViewController *currentVC = [self viewControllerAtIndex:index];
            if (currentVC == nextViewController) {
                [nextViewController endAppearanceTransition];//Did Appear
                [currentViewController endAppearanceTransition];//Did DisAppear
            } else {
                [currentViewController endAppearanceTransition];
                
                [nextViewController beginAppearanceTransition:NO animated:NO];
                [nextViewController endAppearanceTransition];
                [self yyy_removeChildViewController:nextViewController];//移除
                
                [currentVC beginAppearanceTransition:YES animated:YES];
                [currentVC endAppearanceTransition];
            }
            [self yyy_removeChildViewController:currentViewController];//移除
            self.currentIndex = index;
            _nextViewController = nil;
            currentOffsetX = width * self.currentIndex;
        }
        NSInteger nextIndex = 0;
        if (offsetX < currentOffsetX) {
            nextIndex = floor(offsetX/width);
        } else {
            nextIndex = ceil(offsetX/width);
        }
        UIViewController *nextVC = [self viewControllerAtIndex:nextIndex];
        self.nextViewController = nextVC;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageViewController:didScroll:)]) {
        [self.delegate pageViewController:self didScroll:scrollView];
    }
}

#pragma mark - public code
- (void)reloadData {
    if (!_scrollView || !_dataSource) {
        return;
    }
    
    self.count = [self.dataSource numberOfControllersInPageViewController:self];
    NSInteger index = self.currentIndex < self.count ? self.currentIndex : self.count - 1;
    CGFloat width = CGRectGetWidth(self.scrollView.frame);
    [self.scrollView setContentSize:CGSizeMake(width * self.count, CGRectGetHeight(self.scrollView.frame))];
    UIViewController *currentViewController = self.currentViewController;
    [self clearCacheControllerExceptCurrentViewController];
    [self.controllersCache removeAllObjects];
    [self.scrollView setContentOffset:CGPointMake(index * width, 0)];
    //要切换到的viewController
    UIViewController *newController = [self viewControllerAtIndex:index];
    if (currentViewController) {//之前已经有显示一个viewController
        if (newController == nil) {
            //没有任何子ViewController了，所以currentViewController didDisAppear;
            [currentViewController beginAppearanceTransition:NO animated:YES];
            [currentViewController endAppearanceTransition];
            [currentViewController removeFromParentViewController];
            [currentViewController.view removeFromSuperview];
        } else {
            
            if (currentViewController != newController) {
                //切换currentViewController <==> newController
                [newController beginAppearanceTransition:YES animated:YES];
                [currentViewController beginAppearanceTransition:NO animated:YES];
                [self addChildViewControllerToScrollViewAtIndex:index];
                [newController endAppearanceTransition];
                [currentViewController endAppearanceTransition];
                [self yyy_removeChildViewController:currentViewController];
            } else {
                //currentViewController 没改变，调整位置
                currentViewController.view.frame = CGRectMake(width * index, 0, width, CGRectGetHeight(self.scrollView.frame));
            }
        }
    } else {
        if (newController) {
            //加载 newController
            [self addChildViewControllerToScrollViewAtIndex:index];
        }
    }
    self.currentIndex = index;
}

- (void)showViewControllerAtIndex:(NSInteger)index {
    if (index == self.currentIndex || index< 0 || index >= self.count) {
        return;
    }
    
    UIViewController *nextViewController = [self addChildViewControllerToScrollViewAtIndex:index];
    CGFloat width = CGRectGetWidth(self.scrollView.frame);
    if (self.nextViewController) {
        if (nextViewController == self.nextViewController) {
            [self.nextViewController endAppearanceTransition];
            [self.currentViewController endAppearanceTransition];
        } else {
            [self.currentViewController endAppearanceTransition];
            [self.nextViewController beginAppearanceTransition:NO animated:YES];
            [self.nextViewController endAppearanceTransition];
            [self yyy_removeChildViewController:self.nextViewController];
            [nextViewController beginAppearanceTransition:YES animated:YES];
            [nextViewController endAppearanceTransition];
        }
        _nextViewController = nil;
    } else {
        [nextViewController beginAppearanceTransition:YES animated:YES];
        [self.currentViewController beginAppearanceTransition:NO animated:YES];
        [nextViewController endAppearanceTransition];
        [self.currentViewController endAppearanceTransition];
    }
    [self.scrollView setContentOffset:CGPointMake(width * index, self.scrollView.contentOffset.y)];
    [self yyy_removeChildViewController:self.currentViewController];
    self.currentViewController = nextViewController;
    self.currentIndex = index;
}

- (NSInteger)numberOfControllers {
    if (self.count <= 0) {
        self.count = [self.dataSource numberOfControllersInPageViewController:self];
    }
    return self.count;
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.count) {
        return nil;
    }
    UIViewController *vc = [self.controllersCache objectForKey:@(index)];
    if (!vc) {
        vc = [self.dataSource pageViewController:self viewControllerAtIndex:index];
        [self.controllersCache setObject:vc forKey:@(index)];
    }
    return vc;
}

#pragma mark - private code
- (void)updateVisitViewControllerAtScrollView:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat width = CGRectGetWidth(self.scrollView.frame);
    NSInteger index = floor(offsetX/width);
    NSInteger nextIndex = ceil(offsetX/width);
    [self addChildViewControllerToScrollViewAtIndex:index];
    [self addChildViewControllerToScrollViewAtIndex:nextIndex];
}

- (UIViewController *)addChildViewControllerToScrollViewAtIndex:(NSInteger)index {
    UIViewController *vc = [self viewControllerAtIndex:index];
    if (!vc) {
        return nil;
    }
    if (![self.childViewControllers containsObject:vc]) {
        [self addChildViewController:vc];
        [self.scrollView addSubview:vc.view];
        CGFloat width = CGRectGetWidth(self.scrollView.frame);
        vc.view.frame = CGRectMake(width * index, 0, width, CGRectGetHeight(self.scrollView.frame));
        [vc.view layoutIfNeeded];
    }
    return vc;
}

- (void)yyy_removeChildViewController:(UIViewController *)vc {
    if (!vc || ![self.childViewControllers containsObject:vc]) {
        return;
    }
    CGRect frame = vc.view.frame;
    if (CGRectContainsPoint(frame, self.scrollView.contentOffset)) {
        return;
    }
    [vc removeFromParentViewController];
    [vc.view removeFromSuperview];
}

- (void)checkSubViewControllerRemoveFromScrollView {
    if (self.scrollView.isDragging || self.scrollView.isDecelerating) {
        return;
    }
    for (UIViewController *vc in self.controllersCache.allValues.copy) {
        if (self.scrollView.isDragging || self.scrollView.isDecelerating) {
            return;
        }
        if (vc == self.currentViewController) {
            continue;
        } else {
            [self yyy_removeChildViewController:vc];
        }
    }
}

- (void)clearCacheControllerExceptCurrentViewController {
    [self releasetTimerIfNeed];
    //清除缓存VC
    for (NSNumber *key in self.controllersCache.allKeys.copy) {
        UIViewController *vc = self.controllersCache[key];
        CGRect scrollViewVisitFrame = self.scrollView.frame;
        scrollViewVisitFrame.origin.x = self.scrollView.contentOffset.x;
        scrollViewVisitFrame.origin.y = self.scrollView.contentOffset.y;
        if (vc != self.currentViewController &&
            !CGRectIntersectsRect(scrollViewVisitFrame, vc.view.frame)) {
            [vc.view removeFromSuperview];
            [self.controllersCache removeObjectForKey:key];
        }
    }
}

- (void)releasetTimerIfNeed {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - loadSubViews
- (void)loadSubviews {
    _scrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:_scrollView];
    _scrollView.bounces = NO;
    _scrollView.alwaysBounceVertical = NO;
    _scrollView.alwaysBounceHorizontal = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.scrollsToTop = NO;
    if (@available(iOS 11, *)) {
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

#pragma mark - get,set
- (NSMutableDictionary *)controllersCache {
    if (!_controllersCache) {
        _controllersCache = [NSMutableDictionary dictionary];
    }
    return _controllersCache;
}

- (void)setDataSource:(id<YYYPageViewControllerDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        [self reloadData];
    }
}

- (void)setNextViewController:(UIViewController *)nextViewController {
    if (_nextViewController == nextViewController) {
        return;
    }
    if (_nextViewController) {
        [_nextViewController beginAppearanceTransition:NO animated:NO];
        [_nextViewController endAppearanceTransition];
        [_nextViewController removeFromParentViewController];
        [_nextViewController.view removeFromSuperview];
    }
    if (nextViewController) {
        [nextViewController beginAppearanceTransition:YES animated:YES];
        if (_nextViewController == nil) {
            [self.currentViewController beginAppearanceTransition:NO animated:YES];
        }
    }
    _nextViewController = nextViewController;
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    self.currentViewController = [self addChildViewControllerToScrollViewAtIndex:currentIndex];
    if (_currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        if (self.delegate && [self.delegate respondsToSelector:@selector(pageViewController:didScrollToIndex:)]) {
            [self.delegate pageViewController:self didScrollToIndex:currentIndex];
        }
    }
}

@end
