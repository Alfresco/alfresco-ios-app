//
//  FullScreenAnimationController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 04/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "FullScreenAnimationController.h"

@implementation FullScreenAnimationController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.presentationSpeed = 1.0f;
        self.dismissalSpeed = 0.3f;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return (self.isGoingIntoFullscreenMode) ? self.presentationSpeed : self.dismissalSpeed;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    if (self.isGoingIntoFullscreenMode)
    {
        [self executePresentationAnimation:transitionContext];
    }
    else
    {
        [self executeDismissalAnimation:transitionContext];
    }
}

-(void)executePresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    toViewController.view.frame = containerView.frame;
    
    [containerView addSubview:toViewController.view];
    
    // Ask the presented view controller if the status bar should be displayed
    void (^checkAndCallIfStatusBarShouldBeDisplayed)(UIViewController *) = ^(UIViewController *controller) {
        if ([controller conformsToProtocol:@protocol(FullScreenAnimationControllerProtocol)])
        {
            [controller setNeedsStatusBarAppearanceUpdate];
        }
        else
        {
            @throw ([NSException exceptionWithName:@"Protocol Conformance"
                                            reason:[NSString stringWithFormat:@"View controllers that use %@ must conform to %@", NSStringFromClass([self class]), NSStringFromProtocol(@protocol(FullScreenAnimationControllerProtocol))]
                                          userInfo:nil]);
        }
    };
    
    if ([toViewController isKindOfClass:[UINavigationController class]])
    {
        ((UINavigationController *)toViewController).navigationBar.translucent = YES;
        checkAndCallIfStatusBarShouldBeDisplayed([[(UINavigationController *)toViewController viewControllers] lastObject]);
    }
    else
    {
        toViewController.navigationController.navigationBar.translucent = YES;
        checkAndCallIfStatusBarShouldBeDisplayed(toViewController);
    }
    
    [UIView animateWithDuration:self.presentationSpeed delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        toViewController.view.alpha = 1.0f;
        fromViewController.view.alpha = 0.6f;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

-(void)executeDismissalAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    [UIView animateWithDuration:self.dismissalSpeed delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        toViewController.view.alpha = 1.0f;
        fromViewController.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
        // Once the presented controller is dismissed, we ask the presenting controller if the statusbar should be displayed
        [UIView animateWithDuration:0.1f animations:^{
            [toViewController setNeedsStatusBarAppearanceUpdate];
        }];
    }];
}

@end
