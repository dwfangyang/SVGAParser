//
//  SVGAParser.h
//  SVGAParser
//
//  Created by 方阳 on 2019/4/16.
//  Copyright © 2019 方阳. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVGAParser : NSObject

+ (void)extractJsonAndImagesFor:(NSString*)svgaPath;

@end

NS_ASSUME_NONNULL_END
