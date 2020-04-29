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
  
@interface SystemNotice : UIView <UIDynamicAnimatorDelegate>

typedef enum
{
    SystemNoticeStyleInformation = 0,
    SystemNoticeStyleError,
    SystemNoticeStyleWarning
} SystemNoticeStyle;

@property (nonatomic, assign, readonly) SystemNoticeStyle noticeStyle;

/**
 * Public API
 */
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) CGFloat displayTime;

- (id)initWithStyle:(SystemNoticeStyle)style inView:(UIView *)view;
- (void)show;
- (void)canDisplay;

/**
 * Preferred API entrypoints
 */
// Note: Title label is used for a simple information message type
+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message;
+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title;
// Note: An error notice without given title will be given a generic "An Error Occurred" title
+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message;
+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title;
+ (SystemNotice *)showWarningNoticeInView:(UIView *)view message:(NSString *)message;
+ (SystemNotice *)showWarningNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title;
+ (SystemNotice *)systemNoticeWithStyle:(SystemNoticeStyle)style inView:(UIView *)view message:(NSString *)message title:(NSString *)title;

@end
