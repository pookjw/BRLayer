//
//  AppDelegate.mm
//  BRLayer
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import "AppDelegate.hpp"
#import "SceneDelegate.hpp"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    auto configuration = static_cast<UISceneConfiguration *>([connectingSceneSession.configuration copy]);
    configuration.delegateClass = SceneDelegate.class;
    return [configuration autorelease];
}

@end
