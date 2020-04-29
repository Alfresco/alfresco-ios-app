/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
 
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
