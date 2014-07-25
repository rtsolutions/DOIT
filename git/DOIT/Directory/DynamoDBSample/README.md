# The Amazon DynamoDB Object Mapper Sample

This sample demonstrates the DynamoDB object mapper found in the AWS SDK for iOS.

## Requirements

* Xcode 5 and later
* iOS 7 and later

## Using the Sample

1. The AWS Mobile SDK for iOS is available through [CocoaPods](http://cocoapods.org). If you have not installed CocoaPods, install CocoaPods:

		sudo gem install cocoapods

1. To install the AWS Mobile SDK for iOS, simply add the following line to your **Podfile**:

		pod "AWSiOSSDKv2"

	Then run the following command:
	
		pod install

1. In the [Amazon Cognito console](https://console.aws.amazon.com/cognito/), use Amazon Cognito to create a new identity pool. Obtain the `AccountID`, `PoolID`, and `RoleUnauth` constants. Make sure the [role](https://console.aws.amazon.com/iam/home?region=us-east-1#roles) has full permissions for the sample table.

1. Open `DynamoDBSample.xcodeproj`.

1. Open `Constants.m` and update the following lines with the constants from step 1:

        NSString *const AWSAccountID = @"Your-AccountID";
        NSString *const CognitoPoolID = @"Your-PoolID";
        NSString *const CognitoRoleUnauth = @"Your-RoleUnauth"; 

1. Build and run the sample app.