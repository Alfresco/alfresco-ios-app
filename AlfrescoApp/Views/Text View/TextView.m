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

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setup];
}

#pragma mark - Overridden Functions

- (BOOL)hasText
{
    return ![self.text isEqualToString:self.placeholderText] && self.text.length > 0;
}

#pragma mark - Custom Getters/Setters

- (void)setPlaceholderText:(NSString *)placeholderText
{
    _placeholderText = placeholderText;
    self.text = placeholderText;
    self.textColor = [UIColor textDimmedColor];
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
    return self.contentSize;
}

#pragma mark - UITextViewDelegate Functions

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:self.placeholderText])
    {
        textView.text = @"";
        textView.textColor = [UIColor textDefaultColor];
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
        textView.textColor = [UIColor textDimmedColor];
        textView.text = self.placeholderText;
    }
}

@end
