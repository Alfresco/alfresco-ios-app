//
//  ActivityTableViewCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActivityTableViewCell.h"

static CGFloat const kSummaryTextFontSize = 17;

static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression()
{
    if (!__nameRegularExpression)
    {
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"^\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __nameRegularExpression;
}

static NSRegularExpression *__parenthesisRegularExpression;
static inline NSRegularExpression * ParenthesisRegularExpression()
{
    if (!__parenthesisRegularExpression)
    {
        __parenthesisRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\([^\\(\\)]+\\)" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __parenthesisRegularExpression;
}

@implementation ActivityTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.summaryLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        self.summaryLabel.font = [UIFont systemFontOfSize:kSummaryTextFontSize];
        self.summaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.summaryLabel.numberOfLines = 0;
        
        [self.contentView addSubview:self.summaryLabel];
    }
        
    return self;
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.hidden = YES;
        
    self.summaryLabel.frame = self.textLabel.frame;
}

@end
