//
//  MainMenuItemCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 14/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MainMenuItemCell.h"


static NSString * const kMainMenuItemCellIdentifier = @"MainMenuItemCellIdentifier";
static CGFloat const kMainMenuItemCellHeight = 50.0f;

@implementation MainMenuItemCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor appTintColor];
        bgColorView.layer.masksToBounds = YES;
        self.selectedBackgroundView = bgColorView;
    }
    return self;
}

- (void)awakeFromNib
{
    // should be empty by default
    self.menuAccountNameLabel.text = @"";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutSubviews];
    self.menuImageView.layer.cornerRadius = self.menuImageView.frame.size.width / 2;
    self.menuImageView.clipsToBounds = YES;
}

#pragma mark - Public Functions

+ (NSString *)cellIdentifier
{
    return kMainMenuItemCellIdentifier;
}

+ (CGFloat)minimumCellHeight
{
    return kMainMenuItemCellHeight;
}

@end
