//
//  main.m
//  SVGAParser
//
//  Created by 方阳 on 2019/4/16.
//  Copyright © 2019 方阳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVGAParser.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
        NSString* usage = @"\n                              \
SVGAParser: 解析 2.0以上版本的svga文件    \
usage: SVGAParser svgafilepath \n";
        
        opterr = 0;
        NSString* pathSvga = nil;
        int oc; //operation char
        while( (oc = getopt(argc, (char*const*)argv, "c:l:")) != -1 )
        {
            switch ( oc ) {
                case ':':
                case '?':
                {
                    if( optopt == 'h' )
                    {
                        fprintf(stdout, "%s",usage.UTF8String);
                        exit(0);
                    }
                }
                    break;
                    
                default:
                    break;
            }
        }
        if ( optind < argc ) {
            pathSvga = [NSString stringWithUTF8String:argv[optind]];
            
            NSString * currentpath = [[NSFileManager defaultManager] currentDirectoryPath];
            if( ![pathSvga containsString:@"/"] ) {
                pathSvga = [NSString stringWithFormat:@"%@/%@",currentpath,pathSvga];
            }
            if( ![[NSFileManager defaultManager] fileExistsAtPath:pathSvga] ) {
                fprintf(stderr, "file does not exist:%s\n",pathSvga.UTF8String);
                exit(1);
            }
        }
        else
        {
            fprintf(stderr, "please enter svga filepath\n");
            exit(1);
        }
        
        fprintf(stderr, "parsing file:%s\n",pathSvga.UTF8String);
        [SVGAParser extractJsonAndImagesFor:pathSvga];
        exit(0);
    }
}
