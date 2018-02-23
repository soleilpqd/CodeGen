//
//  NSString+encode.m
//  RSUtils
//
//  Created by Some1 on 29/09/2015.
//  Copyright © 2015 GMO-Z.com RunSystem. All rights reserved.
//

#import "NSString+encode.h"
#import <CommonCrypto/CommonDigest.h>
#import "zlib.h"

@implementation NSString (encode)

-( NSString* )base64EncodedString {
    return [[ self dataUsingEncoding:NSUTF8StringEncoding ] base64EncodedStringWithOptions:0 ];
}

-( NSString* )base64DecodedString {
    NSData *decodedData = [[ NSData alloc ] initWithBase64EncodedString:self options:0 ];
    return [[ NSString alloc ] initWithData:decodedData encoding:NSUTF8StringEncoding ];
}

-( NSString* )makeEncodedStringWithDigestLength:( unsigned int )digestLength
                                    andFunction:( unsigned char *(*)(const void *data, CC_LONG len, unsigned char *md ))func {
    NSData *data = [ self dataUsingEncoding:NSUTF8StringEncoding ];
    unsigned char buffer[ digestLength ];
    func( data.bytes, ( unsigned int )data.length, buffer );
    NSMutableString *result = [ NSMutableString new ];
    for ( unsigned int i = 0; i < digestLength; i++ ) {
        [ result appendFormat:@"%02x", buffer[i] ];
    }
    return result;
}

-( NSString* )md2String {
    return [ self makeEncodedStringWithDigestLength:CC_MD2_DIGEST_LENGTH
                                        andFunction:CC_MD2 ];
}

-( NSString* )md4String {
    return [ self makeEncodedStringWithDigestLength:CC_MD4_DIGEST_LENGTH
                                        andFunction:CC_MD4 ];
}

-( NSString* )md5String {
    return [ self makeEncodedStringWithDigestLength:CC_MD5_DIGEST_LENGTH
                                        andFunction:CC_MD5 ];
}

-( NSString* )sha1String {
    return [ self makeEncodedStringWithDigestLength:CC_SHA1_DIGEST_LENGTH
                                        andFunction:CC_SHA1 ];
}

-( NSString* )sha224String {
    return [ self makeEncodedStringWithDigestLength:CC_SHA224_DIGEST_LENGTH
                                        andFunction:CC_SHA224 ];
}

-( NSString* )sha256String {
    return [ self makeEncodedStringWithDigestLength:CC_SHA256_DIGEST_LENGTH
                                        andFunction:CC_SHA256 ];
}

-( NSString* )sha384String {
    return [ self makeEncodedStringWithDigestLength:CC_SHA384_DIGEST_LENGTH
                                        andFunction:CC_SHA384 ];
}

-( NSString* )sha512String {
    return [ self makeEncodedStringWithDigestLength:CC_SHA512_DIGEST_LENGTH
                                        andFunction:CC_SHA512 ];
}

-( NSData* )sha1Data:( NSData* )inputData {
    NSMutableData *result = [ NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_CTX context;
    CC_SHA1_Init( &context );
    CC_SHA1_Update( &context, inputData.bytes, ( CC_LONG )inputData.length );
    CC_SHA1_Final([ result mutableBytes ], &context );
    return result;
}

-( NSString* )sha1HmacStringWithKey:(NSString *)key {
    NSData *inputData = [ self dataUsingEncoding:NSASCIIStringEncoding ];
    NSData *keyData = [ key dataUsingEncoding:NSASCIIStringEncoding ];
    if ( inputData == nil || inputData.length == 0 || keyData == nil || keyData.length == 0 ) return nil;
    
    if ( keyData.length > CC_SHA1_BLOCK_BYTES ){
        keyData = [ self sha1Data:keyData ];
    }
    if ( keyData.length < CC_SHA1_BLOCK_BYTES ){
        NSInteger padSize = CC_SHA1_BLOCK_BYTES - keyData.length;
        NSMutableData *padData = [ NSMutableData dataWithData:keyData ];
        [ padData appendData:[ NSMutableData dataWithLength:padSize ]];
        keyData = padData;
    }
    
    NSMutableData *oKeyPad = [ NSMutableData dataWithLength:CC_SHA1_BLOCK_BYTES ];
    NSMutableData *iKeyPad = [ NSMutableData dataWithLength:CC_SHA1_BLOCK_BYTES ];
    const uint8_t *kdPtr = [ keyData bytes ];
    uint8_t *okpPtr = [ oKeyPad mutableBytes ];
    uint8_t *ikpPtr = [ iKeyPad mutableBytes ];
    memset( okpPtr, 0x5c, CC_SHA1_BLOCK_BYTES );
    memset( ikpPtr, 0x36, CC_SHA1_BLOCK_BYTES );
    for ( NSUInteger i = 0; i < CC_SHA1_BLOCK_BYTES; i++ ){
        okpPtr[i] = okpPtr[i] ^ kdPtr[i];
        ikpPtr[i] = ikpPtr[i] ^ kdPtr[i];
    }
    
    NSMutableData *innerData = [ NSMutableData dataWithData:iKeyPad ];
    [ innerData appendData:inputData ];
    NSData *innerDataHashed = [ self sha1Data:innerData ];
    NSMutableData *outerData = [ NSMutableData dataWithData:oKeyPad ];
    [ outerData appendData:innerDataHashed ];
    NSData *outerHashedData = [ self sha1Data:outerData ];
    
    return [ outerHashedData base64EncodedStringWithOptions:0 ];
}

@end

@implementation NSData (zip)

-( NSData* )gzipInflate {
    if ([self length] == 0) return nil;
    
    unsigned full_length = (unsigned)[self length];
    unsigned half_length = (unsigned)[self length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[self bytes];
    strm.avail_in = (uint)[self length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uint)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}

- (NSData *)gzipDeflate {
    if ([self length] == 0) return [self copy];
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[self bytes];
    strm.avail_in = (uint)[self length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uint)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}

@end

@implementation NSJSONSerialization (string)

+( id )JSONObjectWithString:( NSString *)string options:( NSJSONReadingOptions )opt error:(  NSError** )error {
    NSData *data = [ string dataUsingEncoding:NSUTF8StringEncoding ];
    if ( data != nil ) {
        return [ self JSONObjectWithData:data options:opt error:error ];
    }
    return nil;
}

+( id )JSONObjectWithString:( NSString* )string {
    return [ self JSONObjectWithString:string options:0 error:nil ];
}

+( id )JSONObjectFromData:(NSData *)data {
    if ( data != nil ) {
        return [ self JSONObjectWithData:data options:0 error:nil ];
    }
    return nil;
}

+( NSString* )stringWithJSONObject:( id )obj options:( NSJSONWritingOptions )opt error:( NSError ** )error {
    if ( obj != nil ){
        NSData *data = [ self dataWithJSONObject:obj options:opt error:error ];
        if ( data != nil ) return [[ NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding ];
    }
    return nil;
}

+( NSString* )stringWithJSONObject:( id )obj {
    return [ self stringWithJSONObject:obj options:0 error:nil ];
}

+( NSData* )dataFromJSONObject:( id )obj {
    if ( obj != nil ) {
        return [ self dataWithJSONObject:obj options:0 error:nil ];
    }
    return nil;
}

@end
