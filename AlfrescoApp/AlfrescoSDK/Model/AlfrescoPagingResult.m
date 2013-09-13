/*******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile SDK.
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

#import "AlfrescoPagingResult.h"
#import "AlfrescoInternalConstants.h"

static NSInteger kPagingResultModelVersion = 1;

@interface AlfrescoPagingResult ()
@property (nonatomic, strong, readwrite) NSArray *objects;
@property (nonatomic, assign, readwrite) BOOL hasMoreItems;
@property (nonatomic, assign, readwrite) int totalItems;
@end

@implementation AlfrescoPagingResult


- (id)initWithArray:(NSArray *)objects hasMoreItems:(BOOL)hasMoreItems totalItems:(int)totalItems
{
    self = [super init];
    if (self) 
    {
        self.objects = objects;
        self.hasMoreItems = hasMoreItems;
        self.totalItems = totalItems;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:kPagingResultModelVersion forKey:NSStringFromClass([self class])];
    [aCoder encodeObject:self.objects forKey:@"pagingResultsArray"];
    [aCoder encodeBool:self.hasMoreItems forKey:@"hasMoreItems"];
    [aCoder encodeInt:self.totalItems forKey:@"totalItems"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        //uncomment this line if you need to check the model version
//        NSInteger version = [aDecoder decodeIntForKey:NSStringFromClass([self class])];
        self.objects = [aDecoder decodeObjectForKey:@"pagingResultsArray"];
        self.hasMoreItems = [aDecoder decodeBoolForKey:@"hasMoreItems"];
        self.totalItems = [aDecoder decodeIntForKey:@"totalItems"];
    }
    return self;
}

@end
