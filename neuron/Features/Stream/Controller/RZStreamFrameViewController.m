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

#import "RZStreamFrameViewController.h"
#import "StreamLoadingView.h"
#import "RzUtils.h"
#import "RzApp.h"
#import "StreamManager.h"

@interface RZStreamFrameViewController ()
@property (weak, nonatomic) StreamLoadingView *loadingView;

// For showing customized toast
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIImageView *iconView;

@property (strong, nonatomic) UILabel *debugMessageLabel;
@end

@implementation RZStreamFrameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _loadingView = (StreamLoadingView *) [[NSBundle mainBundle] loadNibNamed:@"StreamLoadingView" owner:self options:nil].firstObject;
    _loadingView.frame = [[UIScreen mainScreen] bounds];
    [self.view addSubview:self.loadingView];
//    _shouldReturnToNexus = YES;
    
    //BIA-1387, remove streaming view zoom action
    UIScrollView *scrollView = [self valueForKey:@"_scrollView"];
    if (scrollView) {
        NSLog(@"Accessed _scrollView during initialization");
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 1.0;
    }

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(applicationWillResignActive:)
//                                                 name:UIApplicationWillResignActiveNotification
//                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    SettingsMenuVC *mainVC = [[RzApp shared] getSettingsMenuVC];
    [mainVC handelReset];
    //can return some error message here
    if (_shouldReturnToNexus) {
        NSURL *url = [NSURL URLWithString:@"Nexus://"];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return true;
}

- (void)stageStarting:(const char *)stageName {
    Log(LOG_I, @"Neuron Starting %s", stageName);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* stageString = [NSString stringWithFormat:@"%s in progress",stageName];
        NSString* lowerCase = [NSString stringWithFormat:@"%@…",Localized(stageString)];
        NSString* titleCase = [[[lowerCase substringToIndex:1] uppercaseString] stringByAppendingString:[lowerCase substringFromIndex:1]];
        [self.loadingView updateLoadingState:titleCase];
    });
}

- (void)connectionStarted {
    [super connectionStarted];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 异步执行的代码
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                self.loadingView.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.loadingView.hidden = YES;
                [self.loadingView streamAppImageStopAnimation];
            }];
        });
    });
    
}

- (void) launchFailed:(NSString*)message {
    Log(LOG_I, @"Launch failed: %@", message);
    BOOL shouldShowRetryAlert = !_haveRetry;
    if (shouldShowRetryAlert) {
        [self showRetryAlert:message];
    } else {
        [self showHelpAlert:message];
    }
}

- (void)showHelpAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Allow the display to go to sleep now
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:Localized(@"Connection Error")
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [Utils addHelpOptionToDialog:alert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            [self returnToMainFrame];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}


- (void)showRetryAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Allow the display to go to sleep now
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:Localized(@"Connection Error")
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            [self returnToMainFrame];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Retry") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
            self.shouldReturnToNexus = NO;
            [self returnToMainFrame];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self postRetryNotification];
            });
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)postRetryNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kRetryStreamingNotification object:nil];
}

- (void)updateOverlayText: (NSString*) text {
    if (text == nil || text.length == 0) {
        return;
    }
    if ([text hasPrefix:@"Video stream:"]) {
        if(!_debugMessageLabel) {
            _debugMessageLabel = [[UILabel alloc] init];
            _debugMessageLabel.font = [UIFont systemFontOfSize:13];
            _debugMessageLabel.numberOfLines = 0;
            _debugMessageLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent: 0.8];
            _debugMessageLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
            [self.view addSubview:_debugMessageLabel];
        }
//        _debugMessageLabel.text = text;
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 4;

        NSDictionary *attributes = @{
            NSFontAttributeName: _debugMessageLabel.font,
            NSParagraphStyleAttributeName: paragraphStyle
        };

        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
        _debugMessageLabel.attributedText = attributedText;

        CGFloat maxWidth = 500.0;
        CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);

        CGSize requiredSize = [_debugMessageLabel sizeThatFits:maxSize];
        _debugMessageLabel.frame = CGRectMake(50, 10, requiredSize.width, requiredSize.height);
    } else {
        [self showToast: text];
    }
}

- (void)showToast: (NSString*) text {
    if(self.textView) {
        [self.textView removeFromSuperview];
        self.textView = nil;
    }
    
    if(self.iconView) {
        [self.iconView removeFromSuperview];
        self.iconView = nil;
    }
    
    if(self.containerView) {
        [self.containerView  removeFromSuperview];
        self.containerView  = nil;
    }
    
    // Create and configure the UITextView
    self.textView = [[UITextView alloc] init];
    self.textView.text = text;
    self.textView.backgroundColor = [UIColor clearColor]; // Transparent background for container view background visibility
    self.textView.alpha = 1.0; // Visible text view
    self.textView.textColor = [UIColor blackColor];
    self.textView.editable = NO;
    self.textView.scrollEnabled = NO;
    [self.textView setFont:[UIFont systemFontOfSize:14]];

    // Calculate the size that best fits the content
    CGSize textSize = [self.textView sizeThatFits:CGSizeMake(CGFLOAT_MAX, FLT_MAX)];

    // Create and configure the UIImageView for the icon
    UIImage *iconImage = [UIImage imageNamed:@"alert_fill"]; // Replace with your icon image name
    self.iconView = [[UIImageView alloc] initWithImage:iconImage];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    CGFloat iconSize = 30; // Define the icon size
    self.iconView.frame = CGRectMake(0, 0, iconSize, iconSize);

    // Create and configure the container UIView
    CGFloat containerPadding = 10;
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, textSize.width + iconSize + containerPadding * 2, textSize.height + containerPadding)];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 3;
    self.containerView.layer.masksToBounds = YES;

    // Set frames for textView and iconView within the container
    self.textView.frame = CGRectMake(containerPadding, containerPadding / 2, textSize.width, textSize.height);
    self.iconView.frame = CGRectMake(CGRectGetMaxX(self.textView.frame), (self.containerView.frame.size.height - iconSize) / 2, iconSize, iconSize);

    // Add the textView and iconView to the container
    [self.containerView addSubview:self.textView];
    [self.containerView addSubview:self.iconView];

    // Center the containerView at the bottom of the screen
    self.containerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - self.containerView.frame.size.height / 2 - 50);

    [self.view addSubview:self.containerView];

    // Animate the appearance of the containerView
    self.containerView.alpha = 0.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.containerView.alpha = 1.0;
    } completion:^(BOOL finished) {
        // After 3 seconds, hide the container view with animation
        [self performSelector:@selector(hideToast) withObject:nil afterDelay:2.6];
    }];
}

- (void)hideToast {
    [UIView animateWithDuration:1.0 animations:^{
        self.containerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.containerView removeFromSuperview];
    }];
}

//- (void)applicationWillResignActive:(NSNotification *)notification {
//    [self returnToMainFrame];
//}
- (void) dealloc {
    NSLog(@"RZStreamFrameViewController deallocated");
}

- (void)updateStatsOverlay {
    StreamManager *_streamMan = [self valueForKey:@"_streamMan"];
    NSString* overlayText = [_streamMan getStatsOverlayText];
    
    if([overlayText hasPrefix:@"Video stream:"]) {
        TemporarySettings *_settings = [self valueForKey:@"_settings"];
        overlayText = [overlayText stringByAppendingString: [NSString stringWithFormat:@"\nmode:%@x%@x%@",_settings.width,_settings.height,_settings.framerate]];
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateOverlayText:overlayText];
    });
}
@end
