/*
 ******************************************************************************
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
 *****************************************************************************
 */

#import "AlfrescoSession.h"
#import "AlfrescoFolder.h"
#import "AlfrescoRepositoryInfo.h"
#import "AlfrescoRequest.h"

/** The AlfrescoRepositorySession manages the session with an Alfresco Repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoRepositorySession : NSObject <AlfrescoSession>

/**---------------------------------------------------------------------------------------
 * @name creates an authenticated instance of the AlfrescoRepositorySession
 *  ---------------------------------------------------------------------------------------
 */
/**
 @param url - the server URL used to establish a session - Required
 @param username The username. - Required
 @param password The password. - Required
 @param completionBlock (AlfrescoSessionCompletionBlock). The block that's called with the session in case the operation succeeds. - required
 @return an instance of the repository session
 */
+ (AlfrescoRequest *)connectWithUrl:(NSURL *)url
                           username:(NSString *)username
                           password:(NSString *)password
                    completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name creates an authenticated instance of the AlfrescoRepositorySession
 *  ---------------------------------------------------------------------------------------
 */
/**
 @param url - the server URL used to establish a session - Required
 @param username The username. - Required
 @param password The password. - Required
 @param parameters a dictionary containing parameters for the session. - Optional (can be nil)
 @param completionBlock (AlfrescoSessionCompletionBlock). The block that's called with the session in case the operation succeeds. - required
 @return an instance of the repository session
 */
+ (AlfrescoRequest *)connectWithUrl:(NSURL *)url
                           username:(NSString *)username
                           password:(NSString *)password
                         parameters:(NSDictionary *)parameters
                    completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;



@end



