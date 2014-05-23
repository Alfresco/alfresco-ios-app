//
//  DatePickerViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@class DatePickerViewController;

@protocol DatePickerViewControllerDelegate <NSObject>

@optional
- (void)datePicker:(DatePickerViewController *)datePicker selectedDate:(NSDate *)date;

@end

@interface DatePickerViewController : UIViewController

- (instancetype)initWithDate:(NSDate *)date;
@property (nonatomic, weak) id<DatePickerViewControllerDelegate> delegate;

@end
