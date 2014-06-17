//
//  TProject.m
//  BetterXib
//
//  Created by 张小刚 on 14-6-17.
//  Copyright (c) 2014年 duohuo. All rights reserved.
//

#import "TProject.h"

@implementation TProject

- (id)initWithName: (NSString *)projectName platform: (BOOL)iosOrMac xibType: (BOOL)xibOrStoryboard
{
    self = [super init];
    if(self){
        self.name = projectName;
        ProjectType type;
        if(iosOrMac){
            if(xibOrStoryboard){
                type = ProjectTypeXib;
            }else{
                type = ProjectTypeStoryboard;
            }
        }else{
            type = ProjectTypeXib;
        }
        self.type = type;
    }
    return self;
}


@end
