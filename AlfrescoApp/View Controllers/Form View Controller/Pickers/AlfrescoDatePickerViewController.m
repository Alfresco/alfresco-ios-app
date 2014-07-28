//
//  AlfrescoDatePickerViewController.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 13/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoDatePickerViewController.h"

@interface AlfrescoDatePickerViewController ()
@property (nonatomic, strong) NSDate *originalDate;
@end

@implementation AlfrescoDatePickerViewController

- (instancetype)initWithDate:(NSDate *)date
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self)
    {
        self.originalDate = date;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // provide Done button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(datePickerDone:)];
    
    // provide a Today button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Today"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(showAndSelectToday:)];
    
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    if (self.originalDate != nil)
    {
        self.datePicker.date = self.originalDate;
    }
}

- (void)showAndSelectToday:(id)sender
{
    [self.datePicker setDate:[NSDate date] animated:YES];
}

- (void)datePickerDone:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(datePicker:didSelectDate:)])
    {
        [self.delegate datePicker:self didSelectDate:self.datePicker.date];
    }
}

@end
