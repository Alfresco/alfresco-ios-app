//
//  AlfrescoListOfValuesPickerViewController.h
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 16/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AlfrescoListOfValuesPickerViewController;

@protocol AlfrescoListOfValuesPickerDelegate <NSObject>
- (void)listOfValuesPicker:(AlfrescoListOfValuesPickerViewController *)listOfValuesPicker didSelectValue:(id)value label:(NSString *)label;
@end

@interface AlfrescoListOfValuesPickerViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) IBOutlet UIPickerView *picker;
@property (nonatomic, weak) id<AlfrescoListOfValuesPickerDelegate> delegate;

- (instancetype)initWithListOfValues:(NSArray *)values labels:(NSArray *)labels selectedValue:(id)selectedValue;

@end
