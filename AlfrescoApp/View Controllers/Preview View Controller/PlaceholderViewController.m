//
//  PlaceholderViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "PlaceholderViewController.h"

CGFloat const kLogoWidthHeight = 300.0f;

@interface PlaceholderViewController ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation PlaceholderViewController

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = view.bounds;
    self.gradientLayer.colors = @[
                                  (id)[[UIColor whiteColor] CGColor],
                                  (id)[[UIColor colorWithWhite:0.9f alpha:1.0f] CGColor]
                                  ];
    [view.layer addSublayer:self.gradientLayer];
    
    UIImage *alfrescoLogo = [UIImage imageNamed:@"alfresco.png"];
    UIImageView *alfrescoLogoImageView = [[UIImageView alloc] initWithImage:alfrescoLogo];
    alfrescoLogoImageView.frame = CGRectMake(0, 0, kLogoWidthHeight, kLogoWidthHeight);
    alfrescoLogoImageView.contentMode = UIViewContentModeScaleAspectFit;
    alfrescoLogoImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    alfrescoLogoImageView.center = view.center;
    [view addSubview:alfrescoLogoImageView];
    
    view.autoresizesSubviews = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view = view;
}

- (void)viewDidLayoutSubviews
{
    self.gradientLayer.frame = self.view.bounds;
}

@end
