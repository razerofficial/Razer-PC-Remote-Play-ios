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

#import "StreamLoadingView.h"

@interface StreamLoadingView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *streamAppImageViewSizeConstraint;

@property (assign, nonatomic) CGFloat rotationAngle;

@property (assign, nonatomic) BOOL continueAnimation;

@end

@implementation StreamLoadingView

- (void)awakeFromNib {
    [super awakeFromNib];
    //NSString *loadingString = @"Starting ";
    NSString *gameName = ShareDataDB.shared.currentLaunchGame.name ?: @"Desktop";
    NSString *loadingString = [NSString stringWithFormat:Localized(@"Starting %@"),gameName];
    [self updateLoadingState:loadingString];
    self.continueAnimation = true;
    [self streamAppImageStartAnimation];
}

-(void)didMoveToSuperview {
    [super didMoveToSuperview];
}

- (void)streamAppImageStartAnimation {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.continueAnimation == true) {
            self.rotationAngle += M_PI * 2 / 3;
            [UIView animateWithDuration:0.25 animations:^{
                self.streamAppImageView.transform = CGAffineTransformMakeRotation(self.rotationAngle);
            }completion:^(BOOL finished) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self streamAppImageStartAnimation];
                });
            }];
        }
    });
}

- (void)streamAppImageStopAnimation {
    
    self.continueAnimation = false;
}

- (void)updateStreamAppImageView {
    
    NSString *device = [UIDevice currentDevice].model;
    
    //iphone
    if ([device isEqualToString:@"iPhone"] || [device isEqualToString:@"iPod touch"]) {
        
        _streamAppImageView.image = [UIImage imageNamed:@"StreamingLoadingLog4iPhone"];
        self.streamAppImageViewSizeConstraint.constant = 64.0;
    }else if ([device isEqualToString:@"iPad"]) {
        _streamAppImageView.image = [UIImage imageNamed:@"StreamingLoadingLog4iPad"];
        self.streamAppImageViewSizeConstraint.constant = 112.0;
    }
}

- (void)updateAppIcon:(UIImage*) icon {
    _streamAppImageView.image = icon;
}

- (void)updateLoadingState:(NSString*) stateString {
    _loadingStateLabel.text = stateString;
}

- (void)setAsReconnectingStyle {
    self.backgroundColor = [UIColor clearColor];
    
    _streamAppImageView.image = [_streamAppImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _streamAppImageView.tintColor = [UIColor whiteColor];
    _loadingStateLabel.textColor = [UIColor whiteColor];
    _loadingStateLabel.text = @"Reconnecting to PC Streaming...";
}
@end
