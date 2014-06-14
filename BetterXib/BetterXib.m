//
//  BetterXib.m
//  BetterXib
//
//  Created by 张小刚 on 14-6-13.
//    Copyright (c) 2014年 duohuo. All rights reserved.
//

#import "BetterXib.h"
#import "AddProjectWindowController.h"

static NSString * const PLUGIN_NAME = @"BetterXib";
static NSString * const WORKING_DIR = @".BetterXib";
static NSString * const PROJECT_DIR = @"Projects";
static NSString * const HELLO_FILE = @"hello.plist";
static NSString * const XIB_SUFFIX = @"xib";
static NSString * const PLIST_LAST_PROJECT = @"lastProjectName";

static BetterXib *sharedPlugin;

@interface BetterXib()
{
    NSArray * _projectNames;
    NSString * _currentProjectName;
    AddProjectWindowController * _addProjectWindowController;
}

@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation BetterXib

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource acccess
        self.bundle = plugin;
        [self initEnvironment];
        [self loadData];
        [self createMenu];
    }
    return self;
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
    for (NSString * projectName in projectNames) {
        if([projectName hasSuffix:xibSuffix]){
            NSString * name = [projectName stringByReplacingOccurrencesOfString: xibSuffix withString:@""];
            if(name.length > 0){
                [projects addObject:name];
            }
        }
    }
    _projectNames = projects;
    if(_projectNames.count > 0){
        //current projectName;
        NSDictionary * helloData = [NSDictionary dictionaryWithContentsOfFile:[self helloPath]];
        NSString * lastProjectName = helloData[PLIST_LAST_PROJECT];
        if(lastProjectName.length > 0 && [_projectNames containsObject:lastProjectName]){
            _currentProjectName = lastProjectName;
        }else{
            _currentProjectName = _projectNames[0];
        }
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
    for (int i=0; i<_projectNames.count; i++) {
        NSString * projectName = _projectNames[i];
        NSMenuItem *projectMenu = [[NSMenuItem alloc] initWithTitle:projectName action:@selector(doProjectMenu:) keyEquivalent:@""];
        if([projectName isEqualToString:_currentProjectName]){
            [projectMenu setState:NSOnState];
        }
        [projectMenu setTarget:self];
        [[mainMenu submenu] addItem:projectMenu];
    }
    if(_projectNames.count > 0){
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
        [_addProjectWindowController setCompleteBlock:^(NSString *projectName, BOOL isPlatformIOS) {
            //projectName exist ?
            BOOL projectNameExists = NO;
            for (NSString * name in bself->_projectNames) {
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
                NSString * templatePath = [bself templatePath:isPlatformIOS];
                templateData = [NSData dataWithContentsOfFile:templatePath];
                NSString * projectPath = [bself projectPath:projectName];
                __autoreleasing NSError * error = nil;
                if(![templateData writeToFile:projectPath options:0 error:&error]){
                    NSLog(@"%@",error);
                }else{
                    //add new project menu
                    NSMenu * mainMenu = [bself mainMenu];
                    if(!mainMenu) return;
                    NSMenuItem * newItem = [[NSMenuItem alloc] initWithTitle:projectName action:@selector(doProjectMenu:) keyEquivalent:@""];
                    [newItem setTarget:bself];
                    [mainMenu insertItem:newItem atIndex:0];
                    [bself setCurrentProject:projectName];
                    NSMutableArray * mutableProjects = [NSMutableArray arrayWithArray: bself->_projectNames.count > 0 ? bself->_projectNames : @[]];
                    [mutableProjects insertObject:projectName atIndex:0];
                    [bself doMainMenu];
                    [bself->_addProjectWindowController close];
                    bself->_addProjectWindowController = nil;
                }
            }
        }];
    }
    [_addProjectWindowController showWindow:nil];
}

- (void)doGoHome
{
    [[NSWorkspace sharedWorkspace] openFile:[self workingDir] withApplication:@"Finder"];
}

- (void)doMainMenu{
    if(_currentProjectName.length == 0){
        [self doAddProject];
    }else{
        NSString * projectPath = [self projectPath:_currentProjectName];
        if(![[NSWorkspace sharedWorkspace] openFile:projectPath withApplication:@"Xcode"]){
            NSLog(@"open fail");
        }
    }
}

- (void)doProjectMenu: (NSMenuItem *)projectMenu{
    NSString * projectName = projectMenu.title;
    NSString * projectPath = [self projectPath:projectName];
    [[NSWorkspace sharedWorkspace] openFile:projectPath withApplication:@"Xcode"];
    [self setCurrentProject:projectName];
}

- (void)setCurrentProject: (NSString *)projectName
{
    if(![projectName isEqualToString:_currentProjectName]){
        _currentProjectName = projectName;
        //save
        NSDictionary * data = @{
                                PLIST_LAST_PROJECT : projectName,
                                };
        [data writeToFile:[self helloPath] atomically:YES];
        
        NSArray * subMenus = [[self mainMenu] itemArray];
        for (NSMenuItem * menuItem in subMenus) {
            menuItem.state = NSOffState;
        }
        [[self projectMenuItem:projectName] setState:NSOnState];
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

- (NSMenuItem *)projectMenuItem: (NSString *)projectName
{
    NSMenu * mainMenu = [self mainMenu];
    return [mainMenu itemWithTitle:projectName];
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

- (NSString *)projectPath: (NSString *)projectName{
    return [NSString stringWithFormat:@"%@/%@.%@",[self projectsDir],projectName,XIB_SUFFIX];
}

- (NSString *)templatePath: (BOOL)isPlatformIOS{
    NSString * resourceName = isPlatformIOS ? @"IOSTemplate" : @"MacTemplate";
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    NSString * templatePath = [bundle pathForResource:resourceName ofType:@"xml"];
    return templatePath;
}


@end
















