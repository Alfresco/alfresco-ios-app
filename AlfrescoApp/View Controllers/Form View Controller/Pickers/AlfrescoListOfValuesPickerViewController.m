//
//  AlfrescoListOfValuesPickerViewController.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 16/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoListOfValuesPickerViewController.h"

@interface AlfrescoListOfValuesPickerViewController ()
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, assign) NSInteger originalSelectedRow;
@property (nonatomic, assign) NSInteger currentSelectedRow;
@end

@implementation AlfrescoListOfValuesPickerViewController

#pragma mark - Initialisation

- (instancetype)initWithListOfValues:(NSArray *)values labels:(NSArray *)labels selectedValue:(id)selectedValue
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self)
    {
        // TODO: do some validation of the given arrays
        
        self.values = values;
        self.labels = (labels != nil) ? labels : values;
        
        // TODO: determine which row should be initally selected
        self.originalSelectedRow = 0;
        self.currentSelectedRow = self.originalSelectedRow;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // provide Done button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(pickerDone:)];
    
    self.picker.delegate = self;
    self.picker.dataSource = self;
    
    [self.picker selectRow:self.originalSelectedRow inComponent:0 animated:NO];
}

#pragma mark -  UIPickerViewDataSource methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.values.count;
}

#pragma mark -  UIPickerViewDelegate methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.labels[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.currentSelectedRow = row;
}

#pragma mark - Event handlers

- (void)pickerDone:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(listOfValuesPicker:didSelectValue:label:)])
    {
        [self.delegate listOfValuesPicker:self didSelectValue:self.values[self.currentSelectedRow] label:self.labels[self.currentSelectedRow]];
    }
}

@end
