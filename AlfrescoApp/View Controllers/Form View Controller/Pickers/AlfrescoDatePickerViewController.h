//
//  AlfrescoDatePickerViewController.h
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 13/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AlfrescoDatePickerViewController;

@protocol AlfrescoDatePickerDelegate <NSObject>
- (void)datePicker:(AlfrescoDatePickerViewController *)datePicker didSelectDate:(NSDate *)date;
@end

@interface AlfrescoDatePickerViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, weak) id<AlfrescoDatePickerDelegate> delegate;

- (instancetype)initWithDate:(NSDate *)date;

@end
