//
//  TProject.h
//  BetterXib
//
//  Created by 张小刚 on 14-6-17.
//  Copyright (c) 2014年 duohuo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ProjectTypeXib = 0,
    ProjectTypeStoryboard = 1,
}ProjectType;

@interface TProject : NSObject

- (id)initWithName: (NSString *)projectName platform: (BOOL)iosOrMac xibType: (BOOL)xibOrStoryboard;

@property (nonatomic, retain) NSString * name;
@property (nonatomic, assign) ProjectType type;

@end
