//
//  RequestHandler.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RequestHandler : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (void)connectWithURL:(NSURL*)requestURL
                method:(NSString *)method
               headers:(NSDictionary *)headers
           requestBody:(NSData *)requestBody
       completionBlock:(AlfrescoDataCompletionBlock)completionBlock;

@end
