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

#import <Foundation/Foundation.h>
#import "CMISProperties.h"
typedef enum {
    HTTP_GET,
    HTTP_POST,
    HTTP_PUT,
    HTTP_DELETE
} CMISHttpRequestMethod;

@class CMISBindingSession, CMISRequest, CMISHttpResponse;


@protocol CMISNetworkProvider <NSObject>

/**
 * CMISNetworkProvider is a protocol used by the CMIS library to invoke network requests. 
 * In case a custom network provider is to be used, this protocol must be implemented and an instance of the
 * custom class provided in the CMISSessionParameters when creating a CMIS Session.
 * CMISSessionParameters provides a networkProvider property for that purpose.
 * All methods in this protocol must be implemented
 */

/**
 * A general invoke method, typically used for GET, DELETE HTTP methods
 * @param url the RESTful API URL to be used
 * @param httpRequestMethod
 * @param session
 * @param body the data for the upload (maybe nil)
 * @param headers any additional headers to be used in the request (maybe nil)
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
          body:(NSData *)body
       headers:(NSDictionary *)additionalHeaders
   cmisRequest:(CMISRequest *)cmisRequest
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;

/**
 * Invoke method used for uploads, i.e. POST/PUT requests
 * @param url the RESTful API URL to be used
 * @param httpRequestMethod
 * @param session
 * @param inputStream the stream pointing to the source to be uploaded. Must be an instance or extension of NSInputStream
 * @param headers any additional headers to be used in the request (maybe nil)
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
   cmisRequest:(CMISRequest *)cmisRequest
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;


/**
 * Invoke method used for uploads, i.e. POST/PUT requests
 * @param url the RESTful API URL to be used
 * @param httpRequestMethod
 * @param session
 * @param inputStream the stream pointing to the source to be uploaded. Must be an instance or extension of NSInputStream
 * @param headers any additional headers to be used in the request (maybe nil)
 * @param bytesExpected the size of the content to be uploaded
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param progressBlock
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
 bytesExpected:(unsigned long long)bytesExpected
   cmisRequest:(CMISRequest *)cmisRequest
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;


/**
 * Invoke method used for uploads, i.e. POST/PUT requests. This method is used for encoding base64 data while streaming
 * @param url the RESTful API URL to be used
 * @param httpRequestMethod
 * @param session
 * @param inputStream the stream pointing to the source to be uploaded. Must be an instance or extension of NSInputStream
 * @param headers any additional headers to be used in the request (maybe nil)
 * @param bytesExpected the size of the content to be uploaded
 * @param cmisRequest will be used to set the cancellable request to the one created by the invode method
 * @param cmisProperties 
 * @param mimeType
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param progressBlock
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
 bytesExpected:(unsigned long long)bytesExpected
   cmisRequest:(CMISRequest *)cmisRequest
cmisProperties:(CMISProperties *)cmisProperties
      mimeType:(NSString *)mimeType
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;



/**
 * Invoke method used for downloads, 
 * @param url the RESTful API URL to be used
 * @param httpRequestMethod
 * @param session
 * @param outputStream the stream pointing to the destination. Must be an instance or extension of NSOutputStream
 * @param bytesExpected the size of the content to be downloaded
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param progressBlock
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
  outputStream:(NSOutputStream *)outputStream
 bytesExpected:(unsigned long long)bytesExpected
   cmisRequest:(CMISRequest *)cmisRequest
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;


/**
 * Convenience GET invoke method
 * @param url the RESTful API URL to be used
 * @param session
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invokeGET:(NSURL *)url
          session:(CMISBindingSession *)session
      cmisRequest:(CMISRequest *)cmisRequest
  completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;



/**
 * Convenience POST invoke method. Use for creating new content
 * @param url the RESTful API URL to be used
 * @param session
 * @param body the data to be posted
 * @param additionalHeaders any additional headers to be used in the request (optional)
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invokePOST:(NSURL *)url
           session:(CMISBindingSession *)session
              body:(NSData *)body
           headers:(NSDictionary *)additionalHeaders
       cmisRequest:(CMISRequest *)cmisRequest
   completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;


/**
 * Convenience PUT invoke method. Use for updating existing content
 * @param url the RESTful API URL to be used
 * @param session
 * @param body the data to be uploaded
 * @param additionalHeaders any additional headers to be used in the request (optional)
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invokePUT:(NSURL *)url
          session:(CMISBindingSession *)session
             body:(NSData *)body
          headers:(NSDictionary *)additionalHeaders
      cmisRequest:(CMISRequest *)cmisRequest
  completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;


/**
 * Convenience DELETE invoke method
 * @param url the RESTful API URL to be used
 * @param session
 * @param completionBlock returns an instance of the HTTPResponse if successful or nil otherwise
 * @param requestObject a handle to the CMISRequest allowing this HTTP request to be cancelled
 */
- (void)invokeDELETE:(NSURL *)url
             session:(CMISBindingSession *)session
         cmisRequest:(CMISRequest *)cmisRequest
     completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;




@end
