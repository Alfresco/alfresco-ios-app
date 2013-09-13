/*
 ******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
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

#import "AlfrescoLog.h"
#import "CMISLog.h"

@implementation AlfrescoLog

#pragma mark - Lifecycle methods

+ (AlfrescoLog *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _logLevel = ALFRESCO_LOG_LEVEL;
    }
    return self;
}

- (void)setLogLevel:(AlfrescoLogLevel)logLevel
{
    _logLevel = logLevel;
    
    // we also need to ensure the CMISLog is kept in sync
    switch (_logLevel)
    {
        case AlfrescoLogLevelOff:
            [CMISLog sharedInstance].logLevel = CMISLogLevelOff;
            break;
            
        case AlfrescoLogLevelError:
            [CMISLog sharedInstance].logLevel = CMISLogLevelError;
            break;
            
        case AlfrescoLogLevelWarning:
            [CMISLog sharedInstance].logLevel = CMISLogLevelWarning;
            break;
            
        case AlfrescoLogLevelInfo:
            [CMISLog sharedInstance].logLevel = CMISLogLevelInfo;
            break;
            
        case AlfrescoLogLevelDebug:
            [CMISLog sharedInstance].logLevel = CMISLogLevelDebug;
            break;
            
        case AlfrescoLogLevelTrace:
            [CMISLog sharedInstance].logLevel = CMISLogLevelTrace;
            break;
            
        default:
            [CMISLog sharedInstance].logLevel = CMISLogLevelInfo;
            break;
    }
}

#pragma mark - Info methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ Log level: %@", [super description], [self stringForLogLevel:self.logLevel]];
}

- (NSString *)stringForLogLevel:(AlfrescoLogLevel)logLevel
{
    NSString *result = nil;
    
    switch(logLevel)
    {
        case AlfrescoLogLevelOff:
            result = @"OFF";
            break;
        case AlfrescoLogLevelError:
            result = @"ERROR";
            break;
        case AlfrescoLogLevelWarning:
            result = @"WARN";
            break;
        case AlfrescoLogLevelInfo:
            result = @"INFO";
            break;
        case AlfrescoLogLevelDebug:
            result = @"DEBUG";
            break;
        case AlfrescoLogLevelTrace:
            result = @"TRACE";
            break;
        default:
            result = @"UNKNOWN";
    }
    
    return result;
}

#pragma mark - Logging methods

- (void)logErrorFromError:(NSError *)error
{
    if (self.logLevel != AlfrescoLogLevelOff)
    {
        NSString *message = [NSString stringWithFormat:@"[%ld] %@", (long)error.code, error.localizedDescription];
        [self logMessage:message forLogLevel:AlfrescoLogLevelError];
    }
}

- (void)logError:(NSString *)format, ...
{
    if (self.logLevel != AlfrescoLogLevelOff)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelError];
    }
}

- (void)logWarning:(NSString *)format, ...
{
    if (self.logLevel >= AlfrescoLogLevelWarning)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelWarning];
    }
}

- (void)logInfo:(NSString *)format, ...
{
    if (self.logLevel >= AlfrescoLogLevelInfo)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelInfo];
    }
}

- (void)logDebug:(NSString *)format, ...
{
    if (self.logLevel >= AlfrescoLogLevelDebug)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelDebug];
    }
}

- (void)logTrace:(NSString *)format, ...
{
    if (self.logLevel == AlfrescoLogLevelTrace)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelTrace];
    }
}

#pragma mark - Helper methods

- (void)logMessage:(NSString *)message forLogLevel:(AlfrescoLogLevel)logLevel
{
    NSString *callingMethod = [self methodNameFromCallStack:[[NSThread callStackSymbols] objectAtIndex:2]];
    NSLog(@"%@ %@ %@", [self stringForLogLevel:logLevel], callingMethod, message);
}

- (NSString *)methodNameFromCallStack:(NSString *)topOfStack
{
    NSString *methodName = nil;
    
    if (topOfStack != nil)
    {
        NSRange startBracketRange = [topOfStack rangeOfString:@"[" options:NSBackwardsSearch];
        if (NSNotFound != startBracketRange.location)
        {
            NSString *start = [topOfStack substringFromIndex:startBracketRange.location];
            NSRange endBracketRange = [start rangeOfString:@"]" options:NSBackwardsSearch];
            if (NSNotFound != endBracketRange.location)
            {
                methodName = [start substringToIndex:endBracketRange.location + 1];
            }
        }
    }
    
    return methodName;
}

@end
