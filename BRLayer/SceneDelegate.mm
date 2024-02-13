//
//  SceneDelegate.mm
//  BRLayer
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import "SceneDelegate.hpp"
#import "ViewController.hpp"

@implementation SceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:static_cast<UIWindowScene *>(scene)];
    ViewController *rootViewController = [ViewController new];
    window.rootViewController = rootViewController;
    [rootViewController release];
    [window makeKeyAndVisible];
    self.window = window;
    [window release];
}

@end
