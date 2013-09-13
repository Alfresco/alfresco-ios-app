/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */

//
// AlfrescoCMISFolder
//
#import "AlfrescoCMISFolder.h"
#import "CMISSession.h"
#import "AlfrescoCMISUtil.h"
#import "CMISConstants.h"


@implementation AlfrescoCMISFolder

- (id)initWithObjectData:(CMISObjectData *)objectData session:(CMISSession *)session
{
    self = [super initWithObjectData:objectData session:session];
    if (self)
    {
        self.aspectTypes = [AlfrescoCMISUtil processExtensionElementsForObject:self];
    }
    return self;
}

- (void)updateProperties:(NSDictionary *)properties completionBlock:(void (^)(CMISObject *object, NSError *error))completionBlock
{
    NSMutableDictionary *aspectAwareProperties = nil;
    if (properties != nil)
    {
        aspectAwareProperties = [[NSMutableDictionary alloc] initWithDictionary:properties];
        
        NSMutableString *objectTypeIdBuilder = [[NSMutableString alloc] init];
        [objectTypeIdBuilder appendString:self.objectType];
        for (NSString *aspectTypeId in self.aspectTypes)
        {
            [objectTypeIdBuilder appendFormat:@", %@", aspectTypeId];
        }
        
        [aspectAwareProperties setValue:objectTypeIdBuilder forKey:kCMISPropertyObjectTypeId];
    }
    [super updateProperties:aspectAwareProperties completionBlock:completionBlock];
}

/*
- (CMISObject *)updateProperties:(NSDictionary *)properties error:(NSError **)error
{
    // We need to 'prepare' the properties first to include all aspects
    NSMutableDictionary *aspectAwareProperties = nil;
    if (properties != nil)
    {
        aspectAwareProperties = [[NSMutableDictionary alloc] initWithDictionary:properties];

        NSMutableString *objectTypeIdBuilder = [[NSMutableString alloc] init];
        [objectTypeIdBuilder appendString:self.objectType];
        for (NSString *aspectTypeId in self.aspectTypes)
        {
            [objectTypeIdBuilder appendFormat:@", %@", aspectTypeId];
        }

        [aspectAwareProperties setValue:objectTypeIdBuilder forKey:kCMISPropertyObjectTypeId];
    }

    return [super updateProperties:aspectAwareProperties error:error];
}
*/

- (BOOL)hasAspect:(NSString *)aspectTypeId
{
    for (NSString *aspect in self.aspectTypes)
    {
        if ([aspect isEqualToString:aspectTypeId])
        {
            return YES;
        }
    }
    return NO;
}


@end