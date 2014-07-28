/*******************************************************************************
* Copyright (C) 2005-2014 Alfresco Software Limited.
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

#import <XCTest/XCTest.h>
#import "AlfrescoFormMandatoryConstraint.h"
#import "AlfrescoFormNumberRangeConstraint.h"
#import "AlfrescoFormListOfValuesConstraint.h"

@interface FormTest : XCTestCase

@end

@implementation FormTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMandatoryConstraints
{
    AlfrescoFormMandatoryConstraint *mandatory = [AlfrescoFormMandatoryConstraint new];
    
    // check default properties
    XCTAssertTrue([mandatory.identifier isEqualToString:kAlfrescoFormConstraintMandatory],
                  @"Expected mandatory constraint identifier to be 'mandatory' but it was %@", mandatory.identifier);
    XCTAssertTrue([mandatory.summary isEqualToString:@"This field is mandatory."],
                  @"Expected mandatory constraint summary to be 'This field is mandatory.' but it was %@", mandatory.summary);
    
    // check basic evaluations
    XCTAssertTrue([mandatory evaluate:@"Testing"], @"Expected a string of 'Testing' to be valid");
    XCTAssertTrue([mandatory evaluate:@(50)], @"Expected an NSNumber representing 50 to be valid");
    XCTAssertFalse([mandatory evaluate:@""], @"Expected an empty string be invalid");
    XCTAssertFalse([mandatory evaluate:nil], @"Expected nil to be invalid");
}

- (void)testNumberRangeConstraints
{
    // create a range constraint from 1 to 10
    AlfrescoFormNumberRangeConstraint *numberRange = [[AlfrescoFormNumberRangeConstraint alloc] initWithMinimum:[NSNumber numberWithInt:1]
                                                                                                        maximum:[NSNumber numberWithInt:10]];
    
    // check default properties
    XCTAssertTrue([numberRange.identifier isEqualToString:kAlfrescoFormConstraintNumberRange],
                  @"Expected number range constraint identifier to be 'numberRange' but it was %@", numberRange.identifier);
    XCTAssertTrue([numberRange.summary isEqualToString:@"The value of this field must be between 1 and 10"],
                  @"Expected number range constraint summary to be 'The value of this field must be between 1 and 10' but it was: %@", numberRange.summary);
    
    // check valid values
    XCTAssertTrue([numberRange evaluate:@(1)], @"Expected 1 to be valid");
    XCTAssertTrue([numberRange evaluate:@(5)], @"Expected 5 to be valid");
    XCTAssertTrue([numberRange evaluate:@(10)], @"Expected 10 to be valid");
    
    // check invalid values
    XCTAssertFalse([numberRange evaluate:@(0)], @"Expected 0 to be invalid");
    XCTAssertFalse([numberRange evaluate:@(11)], @"Expected 11 to be invalid");
    
    // create a range constraint from 0.0 to 1.0
    numberRange = [[AlfrescoFormNumberRangeConstraint alloc] initWithMinimum:[NSNumber numberWithInt:0]
                                                                     maximum:[NSNumber numberWithInt:1]];
    // check valid values
    XCTAssertTrue([numberRange evaluate:@(0)], @"Expected 0 to be valid");
    XCTAssertTrue([numberRange evaluate:@(0.5)], @"Expected 0.5 to be valid");
    XCTAssertTrue([numberRange evaluate:@(1)], @"Expected 1 to be valid");
    
    // check invalid values
    XCTAssertFalse([numberRange evaluate:@(-1)], @"Expected -1 to be invalid");
    XCTAssertFalse([numberRange evaluate:@(1.1)], @"Expected 1.1 to be invalid");
    XCTAssertFalse([numberRange evaluate:@(2)], @"Expected 2 to be invalid");
}

- (void)testListOfValuesConstraint
{
    // create constraint with list of 3 choices
    NSArray *choices = @[@"choice1", @"choice2", @"choice3"];
    AlfrescoFormListOfValuesConstraint *listOfValues = [[AlfrescoFormListOfValuesConstraint alloc] initWithValues:choices labels:choices];
    
    // check default properties
    XCTAssertTrue([listOfValues.identifier isEqualToString:kAlfrescoFormConstraintListOfValues],
                  @"Expected list of values constraint identifier to be 'listOfValues' but it was %@", listOfValues.identifier);
    
    // check valid values
    XCTAssertTrue([listOfValues evaluate:@"choice1"], @"Expected choice1 to be a valid value");
    XCTAssertTrue([listOfValues evaluate:@"choice2"], @"Expected choice2 to be a valid value");
    XCTAssertTrue([listOfValues evaluate:@"choice3"], @"Expected choice3 to be a valid value");
    
    // check invalid values
    XCTAssertFalse([listOfValues evaluate:@"choice4"], @"Expected choice4 to be an invalid value");
    XCTAssertFalse([listOfValues evaluate:nil], @"Expected choice4 to be an invalid value");
}

@end
