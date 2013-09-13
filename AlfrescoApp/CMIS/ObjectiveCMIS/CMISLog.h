/*
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
 */

/**
 * Default logging level
 *
 * The default logging level is Info for release builds and Debug for debug builds.
 * This can easily be overriden in your app's .pch file, e.g.
 *     #define CMIS_LOG_LEVEL CMISLogLevelTrace
 */
#if !defined(CMISLogError)
    #define CMISLogError(...)   [[CMISLog sharedInstance] logError:__VA_ARGS__]
#endif

#if !defined(CMISLogWarning)
    #define CMISLogWarning(...) [[CMISLog sharedInstance] logWarning:__VA_ARGS__]
#endif

#if !defined(CMISLogInfo)
    #define CMISLogInfo(...)    [[CMISLog sharedInstance] logInfo:__VA_ARGS__]
#endif

#if !defined(CMISLogDebug)
    #define CMISLogDebug(...)   [[CMISLog sharedInstance] logDebug:__VA_ARGS__]
#endif

#if !defined(CMISLogTrace)
    #define CMISLogTrace(...)   [[CMISLog sharedInstance] logTrace:__VA_ARGS__]
#endif

#if !defined(CMIS_LOG_LEVEL)
    #if DEBUG
        #define CMIS_LOG_LEVEL CMISLogLevelDebug
    #else
        #define CMIS_LOG_LEVEL CMISLogLevelInfo
    #endif
#endif

#import <Foundation/Foundation.h>


@interface CMISLog : NSObject

typedef NS_ENUM(NSUInteger, CMISLogLevel)
{
    CMISLogLevelOff = 0,
    CMISLogLevelError,
    CMISLogLevelWarning,
    CMISLogLevelInfo,
    CMISLogLevelDebug,
    CMISLogLevelTrace
};

@property (nonatomic, assign) CMISLogLevel logLevel;

/**
 * Returns the shared singleton
 */
+ (CMISLog *)sharedInstance;

/**
 * Designated initializer. Can be used when not instantiating this class in singleton mode.
 */
- (id)initWithLogLevel:(CMISLogLevel)logLevel;

- (NSString *)stringForLogLevel:(CMISLogLevel)logLevel;

- (void)logErrorFromError:(NSError *)error;

- (void)logError:(NSString *)format, ...;

- (void)logWarning:(NSString *)format, ...;

- (void)logInfo:(NSString *)format, ...;

- (void)logDebug:(NSString *)format, ...;

- (void)logTrace:(NSString *)format, ...;


@end
