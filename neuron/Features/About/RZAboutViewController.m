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

#import "RZAboutViewController.h"
#import "SWRevealViewController.h"

@interface RZAboutViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *appIconView;
@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *icpLabelHeight;
@end

@implementation RZAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    
    _appIconView.image = [self getAppIcon];
    _appNameLabel.text = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    _versionLabel.text = [self getAppVersinString];
    _copyrightLabel.text = [self getCopyRightString];
    _icpLabelHeight.constant = [self isChinaRegion] ? 17 : 0;
}

- (UIImage *)getAppIcon {
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSDictionary *iconsDictionary = infoPlist[@"CFBundleIcons"];
    NSDictionary *primaryIconDictionary = iconsDictionary[@"CFBundlePrimaryIcon"];
    NSArray *iconFiles = primaryIconDictionary[@"CFBundleIconFiles"];
    NSString *iconName = [iconFiles lastObject];
    
    UIImage *appIcon = [UIImage imageNamed:iconName];
    return appIcon;
}

- (NSString *)getAppVersinString {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appVersionString = [NSString stringWithFormat:@"Version %@", appVersion];
    return appVersionString;
}

- (NSString *)getCopyRightString {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear fromDate:now];
    NSInteger currentYear = [components year];
    
    NSString *copyRight = [NSString stringWithFormat:@"Copyright © %ld Razer Inc.\nAll rights reserved.", (long)currentYear];
    
    return copyRight;
}

- (BOOL)isChinaRegion {
    NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    return [countryCode isEqual:@"CN"];
}

- (IBAction)onAppIconClicked:(id)sender {
    [self navigateToDev];
}

- (IBAction)onTermsOfServiceClicked:(id)sender {
    Log(LOG_I, @"TermsOfService Clicked");
}
- (IBAction)onPrivacyPolicyClicked:(id)sender {
    Log(LOG_I, @"Privacy Policy Clicked");
}
- (IBAction)onOpenSourceNoticeClicked:(id)sender {
    Log(LOG_I, @"OpenSource Notice Clicked");
}

- (void)navigateToDev {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    SWRevealViewController *revealVC = [storyboard instantiateInitialViewController];
    
    [self.navigationController pushViewController:revealVC animated:true];
}
@end
