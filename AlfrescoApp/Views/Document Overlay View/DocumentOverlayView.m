//
//  DocumentOverlay.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 20/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "DocumentOverlayView.h"

static CGFloat const kToolbarButtonPadding = 5.0f;
static CGFloat const kCloseButtonWidthAndHeight = 50.0f;
static CGFloat const kAnimationSpeed = 0.5f;

@interface DocumentOverlayView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL shouldDisplayCloseButton;
@property (nonatomic, assign) BOOL shouldDisplayExpandButton;
@property (nonatomic, assign, readwrite) BOOL isShowing;
@property (nonatomic, weak) UIButton *closeButton;

@end

@implementation DocumentOverlayView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<DocumentOverlayDelegate>)delegate displayCloseButton:(BOOL)displayCloseButton displayExpandButton:(BOOL)displayExpandButton
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // assign values passed in
        self.delegate = delegate;
        self.shouldDisplayCloseButton = displayCloseButton;
        self.shouldDisplayExpandButton = displayExpandButton;
        
        // overlay view
        self.hidden = YES;
        self.alpha = 0.0f;
        self.autoresizesSubviews = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.userInteractionEnabled = YES;
        
        // tap gesture to dismiss overlay
        UITapGestureRecognizer *dismissOverlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide:)];
        dismissOverlayTap.delegate = self;
        dismissOverlayTap.numberOfTapsRequired = 1;
        dismissOverlayTap.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:dismissOverlayTap];
        
        // dismiss button
        if (self.shouldDisplayCloseButton)
        {
            UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            closeButton.frame = CGRectMake(self.frame.size.width - kCloseButtonWidthAndHeight, kToolbarButtonPadding, kCloseButtonWidthAndHeight, kCloseButtonWidthAndHeight);
            [closeButton setTitle:@"X" forState:UIControlStateNormal];
            [closeButton addTarget:self action:@selector(closeDocument:) forControlEvents:UIControlEventTouchUpInside];
            closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:closeButton];
            self.closeButton = closeButton;
        }
        
        // expand button
        if (self.shouldDisplayExpandButton)
        {
            UIButton *expandButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            expandButton.frame = CGRectMake(kToolbarButtonPadding, kToolbarButtonPadding, kCloseButtonWidthAndHeight, kCloseButtonWidthAndHeight);
            [expandButton setTitle:@"[+]" forState:UIControlStateNormal];
            [expandButton addTarget:self action:@selector(expandCollapseFullscreen:) forControlEvents:UIControlEventTouchUpInside];
            expandButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:expandButton];
        }
    }
    return self;
}

#pragma mark - Public Functions

- (void)show
{
    self.hidden = NO;
    [UIView animateWithDuration:kAnimationSpeed animations:^{
        self.alpha = 1.0f;
    } completion:^(BOOL finished) {
        self.isShowing = YES;
    }];
}

- (void)hide
{
    [self hide:nil];
}

- (void)toggleCloseButtonVisibility
{
    if (self.shouldDisplayCloseButton)
    {
        if (self.closeButton.hidden)
        {
            self.closeButton.hidden = NO;
            [UIView animateWithDuration:kAnimationSpeed animations:^{
                self.alpha = 1.0f;
            }];
        }
        else
        {
            [UIView animateWithDuration:kAnimationSpeed animations:^{
                self.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.closeButton.hidden = YES;
            }];
        }
    }
}

#pragma mark - Private Functions

- (void)hide:(UIGestureRecognizer *)gesture
{
    [UIView animateWithDuration:kAnimationSpeed animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.hidden = YES;
        self.isShowing = NO;
    }];
}

- (void)closeDocument:(UIButton *)sender
{
    [self.delegate documentOverlay:self didPressCloseDocumentButton:sender];
}

- (void)expandCollapseFullscreen:(UIButton *)sender
{
    [self.delegate documentOverlay:self didPressExpandCollapseButton:sender];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *subview in self.subviews)
    {
        if (CGRectContainsPoint(subview.frame, point))
        {
            return YES;
        }
    }
    return NO;
}

@end
