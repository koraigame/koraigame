//
//  Wanikani+Convenience.h
//  wk
//
//  Created by David Sansome on 28/11/17.
//  Copyright © 2017 David Sansome. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Wanikani.pbobjc.h"

@interface WKSubject (Convenience)

@property (nonatomic, readonly) NSString *japanese;
@property (nonatomic, readonly) NSString *primaryMeaning;

@end
