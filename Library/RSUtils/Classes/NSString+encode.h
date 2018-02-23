//
//  NSString+encode.h
//  RSUtils
//
//  Created by Some1 on 29/09/2015.
//  Copyright © 2015 GMO-Z.com RunSystem. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (encode)

-( nonnull NSString* )base64EncodedString;
-( nonnull NSString* )base64DecodedString;
-( nonnull NSString* )md2String;
-( nonnull NSString* )md4String;
-( nonnull NSString* )md5String;
-( nonnull NSString* )sha1String;
-( nonnull NSString* )sha224String;
-( nonnull NSString* )sha256String;
-( nonnull NSString* )sha384String;
-( nonnull NSString* )sha512String;

-( nullable NSString* )sha1HmacStringWithKey:( nonnull NSString* )key;

@end

@interface NSData (zip)

-( nullable NSData* )gzipInflate;
-( nonnull NSData* )gzipDeflate;

@end

@interface NSJSONSerialization(string)

+( nullable id )JSONObjectFromData:( nullable NSData *)data;
+( nullable id )JSONObjectWithString:( nullable NSString *)string;
+( nullable id )JSONObjectWithString:( nullable NSString *)string options:( NSJSONReadingOptions )opt
                               error:(  NSError * _Nullable __autoreleasing * _Nullable )error;

+( nullable NSData* )dataFromJSONObject:( nullable id )obj;
+( nullable NSString* )stringWithJSONObject:( nullable id )obj;
+( nullable NSString* )stringWithJSONObject:( nullable id )obj options:( NSJSONWritingOptions )opt
                                      error:( NSError * _Nullable __autoreleasing * _Nullable )error;

@end
