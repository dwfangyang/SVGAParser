//
//  SVGAParser.m
//  SVGAParser
//
//  Created by 方阳 on 2019/4/16.
//  Copyright © 2019 方阳. All rights reserved.
//

#import "SVGAParser.h"
#import "Svga.pbobjc.h"
#import <zlib.h>
#import "YYModel.h"
#import <AppKit/AppKit.h>

@implementation SVGAParser

+ (void)extractJsonAndImagesFor:(NSString *)svgaPath {
    NSData* data = [NSData dataWithContentsOfFile:svgaPath];
    NSData *tag = nil;
    if (data.length >= 4) {
        tag = [data subdataWithRange:NSMakeRange(0, 4)];
    }
    
    if (![[tag description] isEqualToString:@"<504b0304>"]) {
        // Maybe is SVGA 2.0.0
        NSData *inflateData = [self zlibInflate:data];
        NSError *err;
        SVGAProtoMovieEntity *protoObject = [SVGAProtoMovieEntity parseFromData:inflateData error:&err];
        if (!err) {
//            NSString* json = [protoObject yy_modelToJSONString];
            NSString* curdir = [[NSFileManager defaultManager] currentDirectoryPath];
            NSURL* svgaUrl = [NSURL URLWithString:svgaPath];
            NSString* last = svgaUrl.lastPathComponent;
            NSArray<NSString*>* comps = [last componentsSeparatedByString:@"."];
            NSString* dirpath = nil;
            if( comps.count > 1 ) {
                last = comps[0];
            }
            dirpath = [NSString stringWithFormat:@"%@/%@_images",curdir,last];
            NSError* err;
            NSString* str = protoObject.description;
            NSRange range = [str rangeOfString:@">:"];
            if( range.location != NSNotFound ) {
                str = [str substringFromIndex:range.location+2];
            }
            NSString* jsonpath = [NSString stringWithFormat:@"%@/%@.json",curdir,last];
            [str writeToFile:jsonpath atomically:YES encoding:NSUTF8StringEncoding error:&err];
            fprintf(stdout, "%s.json write to path:%s\n",last.UTF8String,jsonpath.UTF8String);
            if( err ) {
                fprintf(stderr, "SVGA file parse err\n");
                exit(1);
            }
            if( [[NSFileManager defaultManager] fileExistsAtPath:dirpath] ) {
                fprintf(stderr, "imagedir:%s already exists,dump images fail\n",dirpath.UTF8String);
            }
            else {
                [[NSFileManager defaultManager] createDirectoryAtPath:dirpath withIntermediateDirectories:NO attributes:nil error:&err];
                if( err ){
                    fprintf(stderr, "create images dir err\n");
                }
                else {
                    fprintf(stdout, "images dumped to directory:%s\n",dirpath.UTF8String);
                    [self dumpImages:protoObject.images dir:dirpath];
                }
            }
        }
        else {
            fprintf(stderr, "SVGA file parse err\n");
            exit(1);
        }
        return;
    }
    fprintf(stderr, "SVGA 1.0 file is not supported\n");
    exit(1);
}

+ (void)dumpImages:(NSDictionary<NSString*,NSData*>*)images dir:(NSString*)dir{
    for (NSString *key in images) {
        NSString* filePath = [NSString stringWithFormat:@"%@/%@.jpg",dir,key];
        NSImage *image = [[NSImage alloc] initWithData:images[key]];
        
        // Save image.
        NSData *imageData = [image TIFFRepresentation];
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
        NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
        imageData = [imageRep representationUsingType:NSBitmapImageFileTypeJPEG properties:imageProps];
        [imageData writeToFile:filePath atomically:NO];
    }
}

+ (NSData *)zlibInflate:(NSData *)data {
    if ([data length] == 0)
        return data;
    
    unsigned full_length = (unsigned)[data length];
    unsigned half_length = (unsigned)[data length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength:full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[data bytes];
    strm.avail_in = (unsigned)[data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit(&strm) != Z_OK)
        return nil;
    
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy:half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate(&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END)
            done = YES;
        else if (status != Z_OK)
            break;
    }
    if (inflateEnd(&strm) != Z_OK)
        return nil;
    
    // Set real length.
    if (done) {
        [decompressed setLength:strm.total_out];
        return [NSData dataWithData:decompressed];
    } else
        return nil;
}

@end
