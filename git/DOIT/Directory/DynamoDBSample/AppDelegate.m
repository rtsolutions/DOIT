/*
 * Copyright 2010-2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "AppDelegate.h"
#import "AWSCore.h"
#import "Constants.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider credentialsWithRegionType:AWSRegionUSEast1
                                                                                                        accountId:AWSAccountID
                                                                                                   identityPoolId:CognitoPoolID
                                                                                                    unauthRoleArn:CognitoRoleUnauth
                                                                                                      authRoleArn:nil];
    
    
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionUSEast1
                                                                          credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.0 green:158.0/255.0 blue:211.0/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];

    return YES;
}

@end


