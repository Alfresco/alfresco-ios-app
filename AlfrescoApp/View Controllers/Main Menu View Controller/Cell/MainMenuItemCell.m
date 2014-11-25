/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
    
    [self.contentView setNeedsLayout];
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
