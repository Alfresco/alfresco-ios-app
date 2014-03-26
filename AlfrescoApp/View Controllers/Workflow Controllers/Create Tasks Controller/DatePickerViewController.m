//
//  DatePickerViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "DatePickerViewController.h"

@interface DatePickerViewController ()

@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, strong) NSDate *date;

@end

@implementation DatePickerViewController

- (instancetype)initWithDate:(NSDate *)date
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self)
    {
        _date = date;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    if (self.date)
    {
        [_datePicker setDate:self.date animated:YES];
    }
    else
    {
        [_datePicker setDate:[NSDate date] animated:YES];
    }
}

- (void)showAndSelectDate:(NSDate *)date
{
    [self.datePicker setDate:date animated:YES];
}

- (NSDate *)selectedDate
{
    return self.datePicker.date;
}

@end
