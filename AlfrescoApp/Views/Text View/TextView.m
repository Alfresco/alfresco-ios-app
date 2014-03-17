//
//  TextView.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 21/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TextView.h"

static CGFloat const kDefaultMaxHeight = 30.0f;

@interface TextView () <UITextViewDelegate>

@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

@end

@implementation TextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setup];
    }
    return self;
}

-(void) awakeFromNib
{
    [self setup];
}

#pragma mark - Overridden Functions

- (BOOL)hasText
{
    BOOL hasText = NO;
    
    if (![self.text isEqualToString:self.placeholderText] && self.text.length > 0)
    {
        hasText = YES;
    }
    
    return hasText;
}

#pragma mark - Custom Getters/Setters

- (void)setPlaceholderText:(NSString *)placeholderText
{
    _placeholderText = placeholderText;
    self.text = placeholderText;
}

#pragma mark - Private Functions

- (void)setup
{
    self.delegate = self;
    
    for (NSLayoutConstraint *constraint in self.constraints)
    {
        if (constraint.firstAttribute == NSLayoutAttributeHeight)
        {
            self.heightConstraint = constraint;
            break;
        }
    }
}

#pragma mark - Overridden Functions

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize intrinsicSize = self.intrinsicContentSize;
    
    if (self.maximumHeight)
    {
        intrinsicSize.height = MIN(intrinsicSize.height, self.maximumHeight);
    }
    else
    {
        intrinsicSize.height = kDefaultMaxHeight;
    }
    
    self.heightConstraint.constant = intrinsicSize.height;
    
    if ([self.textViewDelegate respondsToSelector:@selector(textViewHeightDidChange:)])
    {
        [self.textViewDelegate textViewHeightDidChange:self];
    }
}

- (CGSize)intrinsicContentSize
{
    CGSize intrinsicContentSize = self.contentSize;
    
    return intrinsicContentSize;
}

#pragma mark - UITextViewDelegate Functions

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:self.placeholderText])
    {
        textView.text = @"";
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedText.length > 0 && ![trimmedText isEqualToString:self.placeholderText])
    {
        if ([self.textViewDelegate respondsToSelector:@selector(textViewDidChange:)])
        {
            [self.textViewDelegate textViewDidChange:self];
        }
    }
    
    // scroll to position while typing
    [self scrollRectToVisible:[self caretRectForPosition:self.selectedTextRange.end] animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView.text.length == 0)
    {
        textView.text = self.placeholderText;
    }
}

@end
