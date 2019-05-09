//
//  BEditProfileTableViewController.m
//  Chat SDK
//
//  Created by Benjamin Smiley-andrews on 25/02/2015.
//  Copyright (c) 2015 deluge. All rights reserved.
//

#import "BEditProfileTableViewController.h"

#import <ChatSDK/Core.h>
#import <ChatSDK/UI.h>

#define bStatusSection 0

@interface BEditProfileTableViewController ()

@end

@implementation BEditProfileTableViewController

@synthesize statusTextView;
@synthesize nameTextField;
@synthesize locationTextField;
@synthesize genderSegmentControl;
@synthesize countryPickerView;
@synthesize allowInvitesFromSegmentControl;
@synthesize didLogout = _didLogout;

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    [self.view addGestureRecognizer:_tapRecognizer];
    
    // Update the user's details
    id<PUser> user = BChatSDK.currentUser;

    // Load the user's information
    statusTextView.text = [user.meta metaStringForKey:bDescription];
    nameTextField.text = user.name;
    locationTextField.text = [user.meta metaStringForKey:bLocation];
    
    NSString * gender = [user.meta metaStringForKey:bGender];
    
    genderSegmentControl.selectedSegmentIndex = [gender isEqualToString:@"M"] ? 0 : 1 ;

    NSString * countryCode = [user.meta metaStringForKey:bCountry];
    countryCode = countryCode ? countryCode : @"GB";
    
    [countryPickerView setSelectedCountryCode:countryCode animated:NO];

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // If we've just logged out then we don't want to do anything
    // because we won't have a Firebase permission
    if (_didLogout) {
        return;
    }
    // #6679 Start bug fix for v3.0.2
    [self updateUserAndIndexes];
    // End bug fix for v3.0.2
    
    //[[NSNotificationCenter defaultCenter] removeObserver:_keyboardObserver];
    
}

-(void) logout {
    
    [self.navigationController popViewControllerAnimated:NO];
    
    // This will prevent the app from trying to
    _didLogout = YES;
    [BChatSDK.auth logout];
    
    // Clear fields
    nameTextField.text = @"";
    locationTextField.text = @"";
}

-(void) viewTapped {
    // Resign first responder for all fields
    [nameTextField resignFirstResponder];
    [locationTextField resignFirstResponder];
    [statusTextView resignFirstResponder];
}

// #6679 Start bug fix for v3.0.2
-(void) updateUserAndIndexes {
    
    // Add the user to the index
    id<PUser> user = BChatSDK.currentUser;
    
    // Get the user's starting meta
    NSDictionary * oldMeta = [user.model meta];
    
    user.name = nameTextField.text;
    
    NSString * gender = genderSegmentControl.selectedSegmentIndex ? @"F" : @"M";
    
    [user updateMeta:@{bDescription: statusTextView.text ? statusTextView.text : @"",
                       bLocation: locationTextField.text ? locationTextField.text : @"",
                       bGender: gender,
                       bCountry: countryPickerView.selectedCountryCode}];
    
    BOOL pushRequired = NO;
    for (NSString * key in [user.model meta]) {
        if (![oldMeta[key] isEqual: [user.model meta][key]]) {
            pushRequired = YES;
            break;
        }
    }
    
    if (pushRequired) {
        [BChatSDK.core pushUser];
    }
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
}

-(BOOL) hidesBottomBarWhenPushed {
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == bStatusSection) {
        float height = statusTextView.heightToFitText + 16;
        height = MIN(height, 300);
        return height;
    }
    return [super tableView: tableView heightForRowAtIndexPath:indexPath];
}

-(void) textViewDidChange:(UITextView *)textView {
    float newHeight = [statusTextView heightToFitText];
    if (newHeight != _statusTextViewHeight) {
        _statusTextViewHeight = newHeight;
        
        [self.tableView reloadData];
        [statusTextView becomeFirstResponder];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString * newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (textView.heightToFitText >= 300 && newText.length > textView.text.length) {
        return NO;
    }
    return YES;
}

- (IBAction)logoutButtonPressed:(id)sender {
    [self logout];
}

- (IBAction)clearLocalData:(id)sender {
    [self logout];
    [BChatSDK.db deleteAllData];
}

@end
