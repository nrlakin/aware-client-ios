//
//  GoogleLoginViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "GoogleLoginViewController.h"
#import "ViewController.h"

@interface GoogleLoginViewController ()

@end

@implementation GoogleLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // -- For Google Login --
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[GIDSignIn sharedInstance] signInSilently];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    [defaults objectForKey:@"GOOGLE_ID"];
//    [defaults objectForKey:@"GOOGLE_NAME"];
//    [defaults objectForKey:@"GOOGLE_ID_TOKEN"];
    NSString *email = [defaults objectForKey:@"GOOGLE_EMAIL"];
    _account.text = email;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Implement these methods only if the GIDSignInUIDelegate is not a subclass of
// UIViewController.

// Stop the UIActivityIndicatorView animation that was started when the user
// pressed the Sign In button
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {

}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults objectForKey:@"GOOGLE_ID"];
    [defaults objectForKey:@"GOOGLE_NAME"];
    [defaults objectForKey:@"GOOGLE_ID_TOKEN"];
    
    NSString *email = [defaults objectForKey:@"GOOGLE_EMAIL"];
    _account.text = email;
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn
dismissViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)didTapSignOut:(id)sender {
    [[GIDSignIn sharedInstance] signOut];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"GOOGLE_ID"];
    [defaults removeObjectForKey:@"GOOGLE_NAME"];
    [defaults removeObjectForKey:@"GOOGLE_EMAIL"];
    [defaults removeObjectForKey:@"GOOGLE_ID_TOKEN"];
    [defaults removeObjectForKey:@"GOOGLE_PHONE"];
    
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Success"
                                                message:nil
                                               delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:@"OK", nil];
    [av show];
    
    _account.text = @"";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
