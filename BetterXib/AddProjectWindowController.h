//
//  AddProjectWindowController.h
//  BetterXib
//
//  Created by 张小刚 on 14-6-14.
//  Copyright (c) 2014年 duohuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AddProjectWindowController : NSWindowController

@property (nonatomic, copy) void (^completeBlock)(NSString * projectName, BOOL isPlatformIOS, BOOL xibOrStoryboard);

@end
