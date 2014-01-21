//
//  TextView.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 21/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TextView;

@protocol TextViewDelegate <NSObject>

@optional
- (void)textViewHeightDidChange:(TextView *)textView;
- (void)textViewDidChange:(TextView *)textView;

@end

@interface TextView : UITextView

@property (nonatomic, assign) CGFloat maximumHeight;
@property (nonatomic, strong) NSString *placeholderText;
@property (nonatomic, weak) IBOutlet id<TextViewDelegate> textViewDelegate;

@end
