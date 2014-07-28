//
//  AlfrescoFormDateCell.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormDateCell.h"

@interface AlfrescoFormDateCell ()
@property (nonatomic, weak) UINavigationController *navigationController;
@end

@implementation AlfrescoFormDateCell

- (void)configureCell
{
    // as we're using the built-in style for date cells, link up the labels
    self.label = self.textLabel;
    
    [super configureCell];
    
    NSLog(@"Configuring date cell for field %@", self.field.identifier);
    
    NSDate *date = self.field.value;
    if (date != nil)
    {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.detailTextLabel.text = [dateFormatter stringFromDate:date];
    }
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.selectable = YES;
}

- (void)didSelectCellWithNavigationController:(UINavigationController *)navigationController
{
    AlfrescoDatePickerViewController *datePickerVC = [[AlfrescoDatePickerViewController alloc] initWithDate:self.field.value];
    datePickerVC.delegate = self;
    self.navigationController = navigationController;
    [self.navigationController pushViewController:datePickerVC animated:YES];
}

- (void)datePicker:(AlfrescoDatePickerViewController *)datePicker didSelectDate:(NSDate *)date
{
    self.field.value = date;
    
    // update the cell to display new date
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    self.detailTextLabel.text = [dateFormatter stringFromDate:self.field.value];
    
    NSLog(@"Date field %@ was edited, value changed to %@", self.field.identifier, self.field.value);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoFormFieldChangedNotification object:self.field];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
