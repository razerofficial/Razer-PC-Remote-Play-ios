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

#ifndef SettingsViewController_Neuron_h
#define SettingsViewController_Neuron_h

#import "SettingsViewController.h"
#import "TemporarySettings.h"

@interface SettingsViewController ()
- (void) updateBitrateText;
- (void) updateResolutionDisplayViewText;
- (int)getSliderValueForBitrate:(NSInteger)bitrate;

- (void)updateSettingUI:(TemporarySettings *)currentSettings;
@end

#endif /* SettingsViewController_Neuron_h */
