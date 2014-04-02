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
    
    if (self.date)
    {
        [self.datePicker setDate:self.date animated:YES];
    }
    else
    {
        [self.datePicker setDate:[NSDate date] animated:YES];
    }
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.title = NSLocalizedString(@"date.picker.title", @"Calendar");
    self.datePicker.minimumDate = [NSDate date];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"date.picker.today", @"Today")
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(showAndSelectToday:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(datePickerDone:)];
}

- (void)showAndSelectToday:(id)sender
{
    [self.datePicker setDate:[NSDate date] animated:YES];
}

- (void)datePickerDone:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(datePicker:selectedDate:)])
    {
        [self.delegate datePicker:self selectedDate:self.datePicker.date];
    }
}

@end
