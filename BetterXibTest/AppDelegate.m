//
//  AppDelegate.m
//  BetterXibTest
//
//  Created by 张小刚 on 14-6-13.
//  Copyright (c) 2014年 duohuo. All rights reserved.
//

#import "AppDelegate.h"
#import "AddProjectWindowController.h"
#import "TProject.h"

static NSString * const PLUGIN_NAME = @"BetterXib";
static NSString * const WORKING_DIR = @".BetterXib";
static NSString * const PROJECT_DIR = @"Projects";
static NSString * const HELLO_FILE = @"hello.plist";
static NSString * const XIB_SUFFIX = @"xib";
static NSString * const STORYBOARD_SUFFIX = @"storyboard";
static NSString * const PLIST_LAST_PROJECT = @"lastProjectName";

@interface AppDelegate ()
{
    NSArray * _projects;
    TProject * _currentProject;
    AddProjectWindowController * _addProjectWindowController;
}
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self go];
}

- (void)go
{
    [self initEnvironment];
    [self loadData];
    [self createMenu];
}

- (void)initEnvironment
{
    //创建工作环境
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL isExists = [fileManager fileExistsAtPath:[self projectsDir] isDirectory:&isDirectory];
    if(!isExists || !isDirectory){
        __autoreleasing NSError * error = nil;
        if(![fileManager createDirectoryAtPath:[self projectsDir] withIntermediateDirectories:YES attributes:nil error:&error]){
            NSLog(@"create project dir error : %@",error);
            abort();
        }
    }
}

- (void)loadData
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSError * error = nil;
    NSArray * projectNames = [fileManager contentsOfDirectoryAtPath:[self projectsDir] error:&error];
    NSMutableArray * projects = [NSMutableArray array];
    
    NSString * xibSuffix = [NSString stringWithFormat:@".%@",XIB_SUFFIX];
    NSString * storyboardSuffix = [NSString stringWithFormat:@".%@",STORYBOARD_SUFFIX];
    for (NSString * projectName in projectNames) {
        if([projectName hasSuffix:xibSuffix] || [projectName hasSuffix:storyboardSuffix]){
            if([projectName hasSuffix:xibSuffix]){
                NSString * name = [projectName stringByReplacingOccurrencesOfString:xibSuffix withString:@""];
                if(name.length > 0){
                    TProject * project = [[TProject alloc] init];
                    project.name = name;
                    project.type = ProjectTypeXib;
                    [projects addObject:project];
                }
            }else if([projectName hasSuffix:storyboardSuffix]){
                NSString * name = [projectName stringByReplacingOccurrencesOfString:storyboardSuffix withString:@""];
                if(name.length > 0){
                    TProject * project = [[TProject alloc] init];
                    project.name = name;
                    project.type = ProjectTypeStoryboard;
                    [projects addObject:project];
                }
            }
        }
    }
    _projects = projects;
    if(_projects.count > 0){
        //current projectName;
        NSDictionary * helloData = [NSDictionary dictionaryWithContentsOfFile:[self helloPath]];
        NSString * lastProjectName = helloData[PLIST_LAST_PROJECT];
        TProject * lastProject = nil;
        if(lastProjectName.length > 0){
            for (TProject * project in _projects) {
                if([project.name isEqualToString:lastProjectName]){
                    lastProject = project;
                    break;
                }
            }
        }
        if(!lastProject){
            lastProject = _projects[0];
        }
        _currentProject = lastProject;
    }
}

- (void)createMenu
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if (!menuItem){
        NSLog(@"not found Window Menu");
    }
    [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
    NSMenuItem *mainMenu = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@",PLUGIN_NAME] action:@selector(doMainMenu) keyEquivalent:@"g"];
    [mainMenu setKeyEquivalentModifierMask:NSControlKeyMask];
    [mainMenu setTarget:self];
    [[menuItem submenu] addItem:mainMenu];
    if(!mainMenu) return;
    NSMenu * subMenu = [[NSMenu alloc] init];
    [mainMenu setSubmenu:subMenu];
    //add project Menu
    for (int i=0; i<_projects.count; i++) {
        TProject * project = _projects[i];
        NSString * projectName = project.name;
        NSMenuItem *projectMenu = [[NSMenuItem alloc] initWithTitle:projectName action:@selector(doProjectMenu:) keyEquivalent:@""];
        if(project == _currentProject){
            [projectMenu setState:NSOnState];
        }
        [projectMenu setTarget:self];
        [[mainMenu submenu] addItem:projectMenu];
    }
    if(_projects.count > 0){
        [[mainMenu submenu] addItem:[NSMenuItem separatorItem]];
    }
    [[mainMenu submenu] addItem:[NSMenuItem separatorItem]];
    //new project menu
    NSMenuItem *addMenu = [[NSMenuItem alloc] initWithTitle:@"新建" action:@selector(doAddProject) keyEquivalent:@""];
    [addMenu setTarget:self];
    [[mainMenu submenu] addItem:addMenu];
    //working dir menu
    NSMenuItem *homeMenu = [[NSMenuItem alloc] initWithTitle:@"工作目录" action:@selector(doGoHome) keyEquivalent:@""];
    [homeMenu setTarget:self];
    [[mainMenu submenu] addItem:homeMenu];
}

- (void)doAddProject
{
    __block typeof(self) bself = self;
    if(!_addProjectWindowController){
        _addProjectWindowController = [[AddProjectWindowController alloc] initWithWindowNibName:@"AddProjectWindowController"];
        [_addProjectWindowController setCompleteBlock:^(NSString *projectName, BOOL isPlatformIOS, BOOL xibOrStoryboard) {
            //projectName exist ?
            BOOL projectNameExists = NO;
            for (TProject * project in bself->_projects) {
                NSString * name = project.name;
                if([name isEqualToString:projectName]){
                    projectNameExists = YES;
                    break;
                }
            }
            if(projectNameExists){
                NSAlert * alert = [NSAlert alertWithMessageText:@"提示" defaultButton:@"确定" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@",@"该项目名已存在"];
                [alert runModal];
            }else{
                NSData * templateData = nil;
                NSString * templatePath = [bself templatePathForPlatform:isPlatformIOS xibOrStoryboard:xibOrStoryboard];
                templateData = [NSData dataWithContentsOfFile:templatePath];
                NSString * projectPath = [bself projectPathFor:projectName platform:isPlatformIOS xibOrStoryboard:xibOrStoryboard];
                __autoreleasing NSError * error = nil;
                if(![templateData writeToFile:projectPath options:0 error:&error]){
                    NSLog(@"%@",error);
                }else{
                    //add new project menu
                    TProject * project = [[TProject alloc] initWithName:projectName platform:isPlatformIOS xibType:xibOrStoryboard];
                    NSMutableArray * mutableProjects = [NSMutableArray arrayWithArray:bself->_projects ? bself->_projects : @[]];
                    [mutableProjects insertObject:project atIndex:0];
                    
                    NSMenu * mainMenu = [bself mainMenu];
                    if(!mainMenu) return;
                    NSMenuItem * newItem = [[NSMenuItem alloc] initWithTitle:projectName action:@selector(doProjectMenu:) keyEquivalent:@""];
                    [newItem setTarget:bself];
                    [mainMenu insertItem:newItem atIndex:0];
                    
                    [bself setCurrentProject:project];
                    [bself doMainMenu]; //手动
                    [bself->_addProjectWindowController close];
                    bself->_addProjectWindowController = nil;
                    
                }
            }
        }];
    }
    NSScreen * screen = [NSScreen mainScreen];
    CGFloat screenWidth = screen.frame.size.width;
    CGFloat screenHeight = screen.frame.size.height;
    CGFloat windowWidth = _addProjectWindowController.window.frame.size.width;
    CGFloat windowHeight = _addProjectWindowController.window.frame.size.height;
    [_addProjectWindowController.window setFrameOrigin :NSMakePoint((screenWidth - windowWidth)/2, (screenHeight - windowHeight - 100))];
    [_addProjectWindowController showWindow:nil];
}

- (void)doGoHome
{
    [[NSWorkspace sharedWorkspace] openFile:[self workingDir] withApplication:@"Finder"];
}

- (void)doMainMenu{
    if(!_currentProject){
        [self doAddProject];
    }else{
        NSString * projectPath = [self projectPath:_currentProject];
        if(![[NSWorkspace sharedWorkspace] openFile:projectPath withApplication:@"Xcode"]){
            NSLog(@"open fail");
        }
    }
}

- (void)doProjectMenu: (NSMenuItem *)projectMenu{
    NSString * projectName = projectMenu.title;
    TProject * project = [self projectByName:projectName];
    NSString * projectPath = [self projectPath:project];
    if(projectPath.length > 0){
        [[NSWorkspace sharedWorkspace] openFile:projectPath withApplication:@"Xcode"];
        [self setCurrentProject:project];
    }
}

- (void)setCurrentProject: (TProject *)project
{
    if(project != _currentProject){
        _currentProject = project;
        //save
        NSDictionary * data = @{
                                PLIST_LAST_PROJECT : project.name,
                                };
        [data writeToFile:[self helloPath] atomically:YES];
        
        NSArray * subMenus = [[self mainMenu] itemArray];
        for (NSMenuItem * menuItem in subMenus) {
            menuItem.state = NSOffState;
        }
        [[self projectMenuItem:project] setState:NSOnState];
    }
}

- (NSMenu *)mainMenu
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if (!menuItem){
        NSLog(@"not found Window Menu");
    }
    NSMenuItem * mainMenuItem = [[menuItem submenu] itemWithTitle:PLUGIN_NAME];
    if(!mainMenuItem) return nil;
    NSMenu * mainMenu = [mainMenuItem submenu];
    return mainMenu;
}

- (NSMenuItem *)projectMenuItem: (TProject *)project
{
    NSMenu * mainMenu = [self mainMenu];
    return [mainMenu itemWithTitle:project.name];
}

- (TProject *)projectByName: (NSString *)projectName
{
    TProject * targetProject = nil;
    for (TProject * project in _projects) {
        if([project.name isEqualToString:projectName]){
            targetProject = project;
            break;
        }
    }
    return targetProject;
}

#pragma mark -----------------   util   ----------------

- (NSString *)workingDir{
    return [NSString stringWithFormat:@"%@/%@",NSHomeDirectory(),WORKING_DIR];
}

- (NSString *)projectsDir{
    return [NSString stringWithFormat:@"%@/%@",[self workingDir],PROJECT_DIR];
}

- (NSString *)helloPath{
    return [NSString stringWithFormat:@"%@/%@",[self workingDir],HELLO_FILE];
}

- (NSString *)projectPath: (TProject *)project{
    if(!project) return nil;
    NSString * suffix = project.type == ProjectTypeXib ? XIB_SUFFIX : STORYBOARD_SUFFIX;
    return [NSString stringWithFormat:@"%@/%@.%@",[self projectsDir],project.name,suffix];
}

- (NSString *)projectPathFor: (NSString *)projectName platform: (BOOL)isPlatformIOS xibOrStoryboard: (BOOL)xibOrStoryboard
{
    if(projectName.length == 0) return nil;
    NSString * suffix = nil;
    {
        if(isPlatformIOS){
            //ios
            suffix = xibOrStoryboard ? XIB_SUFFIX : STORYBOARD_SUFFIX;
        }else{
            //mac
            suffix = XIB_SUFFIX;
        }
    }
    return [NSString stringWithFormat:@"%@/%@.%@",[self projectsDir],projectName,suffix];
}

- (NSString *)templatePathForPlatform: (BOOL)isPlatformIOS xibOrStoryboard: (BOOL)xibOrStoryboard{
    NSString * resourceName = nil;
    {
        if(isPlatformIOS){
            //ios
            resourceName = xibOrStoryboard ? @"IOSTemplate" : @"IOSStoryboardTemplate";
        }else{
            //mac
            resourceName = @"MacTemplate";
        }
    }
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    NSString * templatePath = [bundle pathForResource:resourceName ofType:@"xml"];
    return templatePath;
}


@end









