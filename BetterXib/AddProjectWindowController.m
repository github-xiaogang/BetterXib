//
//  AddProjectWindowController.m
//  BetterXib
//
//  Created by 张小刚 on 14-6-14.
//  Copyright (c) 2014年 duohuo. All rights reserved.
//

#import "AddProjectWindowController.h"

@interface AddProjectWindowController ()

@property (weak) IBOutlet NSTextField *projectNameTextfield;
@property (weak) IBOutlet NSMatrix *typeMatrix;

@end

@implementation AddProjectWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (BOOL)validateInputValues;
{
    BOOL isPassed = NO;
    NSString * alertString = nil;
    do {
        alertString = @"projectName不能为空";
        if(self.projectNameTextfield.stringValue.length == 0) break;
        isPassed = YES;
    } while (false);
    if(!isPassed){
        NSAlert * alert = [NSAlert alertWithMessageText:@"提示" defaultButton:@"确定" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@",alertString];
        [alert runModal];
    }
    return isPassed;
}

- (IBAction)doneButtonPressed:(id)sender {
    if(![self validateInputValues]) return;
    if(_completeBlock){
        _completeBlock(self.projectNameTextfield.stringValue,(self.typeMatrix.selectedRow == 0));
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self close];
}

@end
