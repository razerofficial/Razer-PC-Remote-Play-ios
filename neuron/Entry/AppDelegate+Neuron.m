/*
 * Copyright (C) 2024 Razer Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "AppDelegate.h"
#import "RzApp.h"
#import "RzSwizzling.h"
#import "ShareDataDB.h"
#import "FirebaseCore.h"
#import "Moonlight-Swift.h"

@implementation AppDelegate (Neuron)

+ (void)load {
    [self methodSwizzling];
}

+ (void)methodSwizzling {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RzSwizzling instanceTarget:[AppDelegate new] origSel:@selector(application:didFinishLaunchingWithOptions:) swizzleSel:@selector(rz_application:didFinishLaunchingWithOptions:)];
        [RzSwizzling instanceTarget:[AppDelegate new] origSel:@selector(applicationWillEnterForeground:) swizzleSel:@selector(rz_applicationWillEnterForeground:)];
        [RzSwizzling instanceTarget:[AppDelegate new] origSel:@selector(applicationWillResignActive:) swizzleSel:@selector(rz_applicationWillResignActive:)];
        [RzSwizzling instanceTarget:[AppDelegate new] origSel:@selector(applicationWillTerminate:) swizzleSel:@selector(rz_applicationWillTerminate:)];
        [RzSwizzling instanceTarget:[AppDelegate new] origSel:@selector(applicationDidBecomeActive:) swizzleSel:@selector(rz_applicationDidBecomeActive:)];
    });
}

#pragma mark -- Swizzle methods
- (BOOL)rz_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    Log(LOG_I, NSStringFromSelector(_cmd));
    //call original implementation
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    //SettingsMenuVC *mainVC = [[SettingsMenuVC alloc]init];
    DashboardVC *mainVC = [[DashboardVC alloc] init];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController: mainVC];
    navVC.navigationBarHidden = true;
    navVC.navigationBar.tintColor = [UIColor whiteColor];
    navVC.navigationBar.barTintColor = [UIColor blackColor];
    navVC.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    navVC.navigationBar.translucent = false;
    navVC.navigationBar.backgroundColor = [UIColor blackColor];
    SettingsRouter.shared.navigationController = navVC;
    self.window.rootViewController = navVC;
    [self.window makeKeyAndVisible];
    
    BOOL ret = [self rz_application:application didFinishLaunchingWithOptions:launchOptions];
    //nexus->neuron
    [[ShareDataDB shared] readSettingDataFromShareDB];
    [[ShareDataDB shared] readHostListDataFromeShareDB];
    
    //delate to start , need time to read share host list
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [HostListManger.shared restartDiscovery];
    });
    
    [FIRApp configure];
    return ret;
}

- (void)rz_applicationWillEnterForeground:(UIApplication *)application
{
    Log(LOG_I, NSStringFromSelector(_cmd));
    //call original implementation
    [self rz_applicationWillEnterForeground:application];
    //nexus->neuron
    [[ShareDataDB shared] readSettingDataFromShareDB];
    [[ShareDataDB shared] readHostListDataFromeShareDB];
    [HostListManger.shared restartDiscovery];
    
//    if ( [SettingsRouter shared].hostDevicesReadShareDataCallBack != nil ) {
//        //[SettingsRouter shared].hostDevicesReadShareDataCallBack();
//    }
}

- (void)rz_applicationWillResignActive:(UIApplication *)application
{
    Log(LOG_I, NSStringFromSelector(_cmd));
    //call original implementation
    [self rz_applicationWillResignActive:application];
}

- (void)rz_applicationWillTerminate:(UIApplication *)application
{
    Log(LOG_I, NSStringFromSelector(_cmd));
    //call original implementation
    [self rz_applicationWillTerminate:application];
}

- (void)rz_applicationDidBecomeActive:(UIApplication *)application {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AppStoreReviewHandler.shared checkIsStartAppReiew];
    });
}

#pragma mark -- openurl
- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    [AppStoreReviewHandler.shared markLuanchFromStreamingWithLaunch:true];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //parse url from other apps here...
        [[RzApp shared] maybeStartStreaming];
    });
    
    return YES;
}

@end
