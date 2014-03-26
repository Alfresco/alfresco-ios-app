//
//  DatePickerViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DatePickerViewController : UIViewController

- (instancetype)initWithDate:(NSDate *)date;

- (void)showAndSelectDate:(NSDate *)date;
- (NSDate *)selectedDate;

@end
