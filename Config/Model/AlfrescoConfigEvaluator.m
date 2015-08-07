/*
 ******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 *****************************************************************************
 */

#import "AlfrescoConfigEvaluator.h"
#import "AlfrescoConstants.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoRepositoryInfo.h"
#import "AlfrescoLog.h"

@interface AlfrescoConfigEvaluator ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSDictionary *parameters;
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@end

@implementation AlfrescoConfigEvaluator

- (instancetype)initWithIdentifier:(NSString *)identifier parameters:(NSDictionary *)parameters session:(id<AlfrescoSession>)session
{
    self = [super init];
    if (nil != self)
    {
        self.identifier = identifier;
        self.parameters = parameters;
        self.session = session;
    }
    
    return self;
}

- (BOOL)evaluate:(AlfrescoConfigScope *)scope
{
    // This method should never be called, it MUST be overridden by a subclass
    NSException *exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Subclass should override this method."
                                                   userInfo:nil];
    @throw exception;
}

@end

@implementation AlfrescoMatchEvaluator : AlfrescoConfigEvaluator

- (BOOL)evaluate:(AlfrescoConfigScope *)scope
{
    BOOL matchAll = [self.parameters[kAlfrescoConfigEvaluatorParameterMatchAll] boolValue];
    BOOL result = matchAll;
    NSArray *evaluatorIds = self.parameters[kAlfrescoConfigEvaluatorParameterEvaluatorIds];
    
    // we need the evaluators and evaluatorIds to continue
    if (self.evaluators != nil && self.evaluators.count > 0 && evaluatorIds != nil && evaluatorIds.count > 0)
    {
        for (NSString *evaluatorId in evaluatorIds)
        {
            id<AlfrescoConfigEvaluator> evaluator = self.evaluators[evaluatorId];
            if (evaluator != nil)
            {
                BOOL evaluatorResult = [evaluator evaluate:scope];
                if (matchAll && !evaluatorResult)
                {
                    // if the evaluator failed and we're in match all mode we can return now
                    result = NO;
                    break;
                }
                else if (!matchAll && evaluatorResult)
                {
                    // if the evaluator passed and we're in match any mode we can return now
                    result = YES;
                    break;
                }
            }
            else
            {
                AlfrescoLogWarning(@"%@ references an unknown evaluator: %@", self.identifier, evaluatorId);
            }
        }
    }
    
    return result;
}

@end

// TODO: replace this implementation with AlfrescoRepositoryCapabilitiesEvaluator
@implementation AlfrescoRepositoryVersionEvaluator

- (BOOL)evaluate:(AlfrescoConfigScope *)scope
{
    BOOL result = NO;
    
    if (self.session != nil)
    {
        AlfrescoRepositoryInfo *repoInfo = self.session.repositoryInfo;
        NSString *edition = self.parameters[kAlfrescoConfigEvaluatorParameterEdition];
        
        // check edition first
        if (edition == nil || [edition isEqualToString:repoInfo.edition])
        {
            NSString *operator = self.parameters[kAlfrescoConfigEvaluatorParameterOperator];
            int configVersionTotal = 0;
            int repoVersionTotal = 0;
            int major = [self.parameters[kAlfrescoConfigEvaluatorParameterMajorVersion] intValue];
            int minor = [self.parameters[kAlfrescoConfigEvaluatorParameterMinorVersion] intValue];
            id maintenanceObject = self.parameters[kAlfrescoConfigEvaluatorParameterMaintenanceVersion];
            
            // we need at least the operator, major version and repoInfo to continue
            if (operator != nil && major != -1 && repoInfo != nil)
            {
                // multiply major version by 100
                configVersionTotal += 100 * major;
                repoVersionTotal += 100 * [repoInfo.majorVersion intValue];
                
                // multiply minor version by 10
                configVersionTotal += 10 * minor;
                repoVersionTotal += 10 * [repoInfo.minorVersion intValue];
                
                int maintenance = 0;
                if (maintenanceObject != nil)
                {
                    if ([repoInfo.edition isEqualToString:kAlfrescoRepositoryEditionEnterprise])
                    {
                        maintenance = [((NSNumber *)maintenanceObject) intValue];
                        configVersionTotal += maintenance;
                        repoVersionTotal += [repoInfo.maintenanceVersion intValue];
                    }
                    else if ([repoInfo.edition isEqualToString:kAlfrescoRepositoryEditionCommunity])
                    {
                        // handle a, b, c, d versions
                    }
                }
                            
                if ([operator isEqualToString:@">"])
                {
                    result = repoVersionTotal > configVersionTotal;
                }
                else if ([operator isEqualToString:@"<"])
                {
                    result = repoVersionTotal < configVersionTotal;
                }
                else if ([operator isEqualToString:@"<="])
                {
                    result = repoVersionTotal <= configVersionTotal;
                }
                else if ([operator isEqualToString:@">="])
                {
                    result = repoVersionTotal >= configVersionTotal;
                }
                else
                {
                    result = (repoVersionTotal == configVersionTotal);
                }
            }
        }
        else
        {
            result = NO;
        }
    }
    else
    {
        AlfrescoLogWarning(@"Can not process repository version evaluator without a session object!");
    }
    
    return result;
}

@end

@implementation AlfrescoNodeTypeEvaluator

- (BOOL)evaluate:(AlfrescoConfigScope *)scope
{
    BOOL result = NO;
    
    NSString *typeName = self.parameters[kAlfrescoConfigEvaluatorParameterTypeName];
    AlfrescoNode *node = [scope valueForKey:kAlfrescoConfigScopeContextNode];
    if (node != nil && typeName != nil)
    {
        result = [node.type isEqualToString:typeName];
    }
    
    return result;
}

@end

@implementation AlfrescoAspectEvaluator

- (BOOL)evaluate:(AlfrescoConfigScope *)scope
{
    BOOL result = NO;
    
    NSString *aspectName = self.parameters[kAlfrescoConfigEvaluatorParameterAspectName];
    AlfrescoNode *node = [scope valueForKey:kAlfrescoConfigScopeContextNode];
    if (node != nil && aspectName != nil)
    {
        result = [node hasAspectWithName:aspectName];
    }
    
    return result;
}

@end

@implementation AlfrescoProfileEvaluator

- (BOOL)evaluate:(AlfrescoConfigScope *)scope
{
    NSString *profileParameter = self.parameters[kAlfrescoConfigEvaluatorParameterProfile];
    return [scope.profile isEqualToString:profileParameter];
}

@end

@implementation AlfrescoFormModeEvaluator

- (BOOL)evaluate:(AlfrescoConfigScope *)scope
{
    NSString *evaluatorMode = self.parameters[kAlfrescoConfigEvaluatorParameterMode];
    NSString *scopeMode = [scope valueForKey:kAlfrescoConfigScopeContextFormMode];
    
    return [evaluatorMode isEqualToString:scopeMode];
}

@end

