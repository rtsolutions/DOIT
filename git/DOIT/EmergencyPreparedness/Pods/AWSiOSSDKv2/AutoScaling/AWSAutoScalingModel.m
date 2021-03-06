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

#import "AWSAutoScalingModel.h"
#import "AZCategory.h"

NSString *const AWSAutoScalingErrorDomain = @"com.amazonaws.AWSAutoScalingErrorDomain";

@implementation AWSAutoScalingActivitiesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"activities" : @"Activities",
             @"nextToken" : @"NextToken",
             };
}

+ (NSValueTransformer *)activitiesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingActivity class]];
}

@end

@implementation AWSAutoScalingActivity

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"activityId" : @"ActivityId",
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"cause" : @"Cause",
             @"description" : @"Description",
             @"details" : @"Details",
             @"endTime" : @"EndTime",
             @"progress" : @"Progress",
             @"startTime" : @"StartTime",
             @"statusCode" : @"StatusCode",
             @"statusMessage" : @"StatusMessage",
             };
}

+ (NSValueTransformer *)endTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)startTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)statusCodeJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSNumber *(NSString *value) {
        if ([value isEqualToString:@"WaitingForSpotInstanceRequestId"]) {
            return @(AWSAutoScalingScalingActivityStatusCodeWaitingForSpotInstanceRequestId);
        }
        if ([value isEqualToString:@"WaitingForSpotInstanceId"]) {
            return @(AWSAutoScalingScalingActivityStatusCodeWaitingForSpotInstanceId);
        }
        if ([value isEqualToString:@"WaitingForInstanceId"]) {
            return @(AWSAutoScalingScalingActivityStatusCodeWaitingForInstanceId);
        }
        if ([value isEqualToString:@"PreInService"]) {
            return @(AWSAutoScalingScalingActivityStatusCodePreInService);
        }
        if ([value isEqualToString:@"InProgress"]) {
            return @(AWSAutoScalingScalingActivityStatusCodeInProgress);
        }
        if ([value isEqualToString:@"Successful"]) {
            return @(AWSAutoScalingScalingActivityStatusCodeSuccessful);
        }
        if ([value isEqualToString:@"Failed"]) {
            return @(AWSAutoScalingScalingActivityStatusCodeFailed);
        }
        if ([value isEqualToString:@"Cancelled"]) {
            return @(AWSAutoScalingScalingActivityStatusCodeCancelled);
        }
        return @(AWSAutoScalingScalingActivityStatusCodeUnknown);
    } reverseBlock:^NSString *(NSNumber *value) {
        switch ([value integerValue]) {
            case AWSAutoScalingScalingActivityStatusCodeWaitingForSpotInstanceRequestId:
                return @"WaitingForSpotInstanceRequestId";
            case AWSAutoScalingScalingActivityStatusCodeWaitingForSpotInstanceId:
                return @"WaitingForSpotInstanceId";
            case AWSAutoScalingScalingActivityStatusCodeWaitingForInstanceId:
                return @"WaitingForInstanceId";
            case AWSAutoScalingScalingActivityStatusCodePreInService:
                return @"PreInService";
            case AWSAutoScalingScalingActivityStatusCodeInProgress:
                return @"InProgress";
            case AWSAutoScalingScalingActivityStatusCodeSuccessful:
                return @"Successful";
            case AWSAutoScalingScalingActivityStatusCodeFailed:
                return @"Failed";
            case AWSAutoScalingScalingActivityStatusCodeCancelled:
                return @"Cancelled";
            case AWSAutoScalingScalingActivityStatusCodeUnknown:
            default:
                return nil;
        }
    }];
}

@end

@implementation AWSAutoScalingActivityType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"activity" : @"Activity",
             };
}

+ (NSValueTransformer *)activityJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[AWSAutoScalingActivity class]];
}

@end

@implementation AWSAutoScalingAdjustmentType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"adjustmentType" : @"AdjustmentType",
             };
}

@end

@implementation AWSAutoScalingAlarm

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"alarmARN" : @"AlarmARN",
             @"alarmName" : @"AlarmName",
             };
}

@end

@implementation AWSAutoScalingAttachInstancesQuery

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"instanceIds" : @"InstanceIds",
             };
}

@end

@implementation AWSAutoScalingAutoScalingGroup

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupARN" : @"AutoScalingGroupARN",
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"availabilityZones" : @"AvailabilityZones",
             @"createdTime" : @"CreatedTime",
             @"defaultCooldown" : @"DefaultCooldown",
             @"desiredCapacity" : @"DesiredCapacity",
             @"enabledMetrics" : @"EnabledMetrics",
             @"healthCheckGracePeriod" : @"HealthCheckGracePeriod",
             @"healthCheckType" : @"HealthCheckType",
             @"instances" : @"Instances",
             @"launchConfigurationName" : @"LaunchConfigurationName",
             @"loadBalancerNames" : @"LoadBalancerNames",
             @"maxSize" : @"MaxSize",
             @"minSize" : @"MinSize",
             @"placementGroup" : @"PlacementGroup",
             @"status" : @"Status",
             @"suspendedProcesses" : @"SuspendedProcesses",
             @"tags" : @"Tags",
             @"terminationPolicies" : @"TerminationPolicies",
             @"VPCZoneIdentifier" : @"VPCZoneIdentifier",
             };
}

+ (NSValueTransformer *)createdTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)enabledMetricsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingEnabledMetric class]];
}

+ (NSValueTransformer *)instancesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingInstance class]];
}

+ (NSValueTransformer *)suspendedProcessesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingSuspendedProcess class]];
}

+ (NSValueTransformer *)tagsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingTagDescription class]];
}

@end

@implementation AWSAutoScalingAutoScalingGroupNamesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupNames" : @"AutoScalingGroupNames",
             @"maxRecords" : @"MaxRecords",
             @"nextToken" : @"NextToken",
             };
}

@end

@implementation AWSAutoScalingAutoScalingGroupsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroups" : @"AutoScalingGroups",
             @"nextToken" : @"NextToken",
             };
}

+ (NSValueTransformer *)autoScalingGroupsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingAutoScalingGroup class]];
}

@end

@implementation AWSAutoScalingAutoScalingInstanceDetails

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"availabilityZone" : @"AvailabilityZone",
             @"healthStatus" : @"HealthStatus",
             @"instanceId" : @"InstanceId",
             @"launchConfigurationName" : @"LaunchConfigurationName",
             @"lifecycleState" : @"LifecycleState",
             };
}

@end

@implementation AWSAutoScalingAutoScalingInstancesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingInstances" : @"AutoScalingInstances",
             @"nextToken" : @"NextToken",
             };
}

+ (NSValueTransformer *)autoScalingInstancesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingAutoScalingInstanceDetails class]];
}

@end

@implementation AWSAutoScalingBlockDeviceMapping

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"deviceName" : @"DeviceName",
             @"ebs" : @"Ebs",
             @"noDevice" : @"NoDevice",
             @"virtualName" : @"VirtualName",
             };
}

+ (NSValueTransformer *)ebsJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[AWSAutoScalingEbs class]];
}

@end

@implementation AWSAutoScalingCreateAutoScalingGroupType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"availabilityZones" : @"AvailabilityZones",
             @"defaultCooldown" : @"DefaultCooldown",
             @"desiredCapacity" : @"DesiredCapacity",
             @"healthCheckGracePeriod" : @"HealthCheckGracePeriod",
             @"healthCheckType" : @"HealthCheckType",
             @"instanceId" : @"InstanceId",
             @"launchConfigurationName" : @"LaunchConfigurationName",
             @"loadBalancerNames" : @"LoadBalancerNames",
             @"maxSize" : @"MaxSize",
             @"minSize" : @"MinSize",
             @"placementGroup" : @"PlacementGroup",
             @"tags" : @"Tags",
             @"terminationPolicies" : @"TerminationPolicies",
             @"VPCZoneIdentifier" : @"VPCZoneIdentifier",
             };
}

+ (NSValueTransformer *)tagsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingTag class]];
}

@end

@implementation AWSAutoScalingCreateLaunchConfigurationType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"associatePublicIpAddress" : @"AssociatePublicIpAddress",
             @"blockDeviceMappings" : @"BlockDeviceMappings",
             @"ebsOptimized" : @"EbsOptimized",
             @"iamInstanceProfile" : @"IamInstanceProfile",
             @"imageId" : @"ImageId",
             @"instanceId" : @"InstanceId",
             @"instanceMonitoring" : @"InstanceMonitoring",
             @"instanceType" : @"InstanceType",
             @"kernelId" : @"KernelId",
             @"keyName" : @"KeyName",
             @"launchConfigurationName" : @"LaunchConfigurationName",
             @"placementTenancy" : @"PlacementTenancy",
             @"ramdiskId" : @"RamdiskId",
             @"securityGroups" : @"SecurityGroups",
             @"spotPrice" : @"SpotPrice",
             @"userData" : @"UserData",
             };
}

+ (NSValueTransformer *)blockDeviceMappingsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingBlockDeviceMapping class]];
}

+ (NSValueTransformer *)instanceMonitoringJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[AWSAutoScalingInstanceMonitoring class]];
}

@end

@implementation AWSAutoScalingCreateOrUpdateTagsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"tags" : @"Tags",
             };
}

+ (NSValueTransformer *)tagsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingTag class]];
}

@end

@implementation AWSAutoScalingDeleteAutoScalingGroupType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"forceDelete" : @"ForceDelete",
             };
}

@end

@implementation AWSAutoScalingDeleteNotificationConfigurationType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"topicARN" : @"TopicARN",
             };
}

@end

@implementation AWSAutoScalingDeletePolicyType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"policyName" : @"PolicyName",
             };
}

@end

@implementation AWSAutoScalingDeleteScheduledActionType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"scheduledActionName" : @"ScheduledActionName",
             };
}

@end

@implementation AWSAutoScalingDeleteTagsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"tags" : @"Tags",
             };
}

+ (NSValueTransformer *)tagsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingTag class]];
}

@end

@implementation AWSAutoScalingDescribeAccountLimitsAnswer

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"maxNumberOfAutoScalingGroups" : @"MaxNumberOfAutoScalingGroups",
             @"maxNumberOfLaunchConfigurations" : @"MaxNumberOfLaunchConfigurations",
             };
}

@end

@implementation AWSAutoScalingDescribeAdjustmentTypesAnswer

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"adjustmentTypes" : @"AdjustmentTypes",
             };
}

+ (NSValueTransformer *)adjustmentTypesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingAdjustmentType class]];
}

@end

@implementation AWSAutoScalingDescribeAutoScalingInstancesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"instanceIds" : @"InstanceIds",
             @"maxRecords" : @"MaxRecords",
             @"nextToken" : @"NextToken",
             };
}

@end

@implementation AWSAutoScalingDescribeAutoScalingNotificationTypesAnswer

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingNotificationTypes" : @"AutoScalingNotificationTypes",
             };
}

@end

@implementation AWSAutoScalingDescribeMetricCollectionTypesAnswer

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"granularities" : @"Granularities",
             @"metrics" : @"Metrics",
             };
}

+ (NSValueTransformer *)granularitiesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingMetricGranularityType class]];
}

+ (NSValueTransformer *)metricsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingMetricCollectionType class]];
}

@end

@implementation AWSAutoScalingDescribeNotificationConfigurationsAnswer

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"nextToken" : @"NextToken",
             @"notificationConfigurations" : @"NotificationConfigurations",
             };
}

+ (NSValueTransformer *)notificationConfigurationsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingNotificationConfiguration class]];
}

@end

@implementation AWSAutoScalingDescribeNotificationConfigurationsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupNames" : @"AutoScalingGroupNames",
             @"maxRecords" : @"MaxRecords",
             @"nextToken" : @"NextToken",
             };
}

@end

@implementation AWSAutoScalingDescribePoliciesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"maxRecords" : @"MaxRecords",
             @"nextToken" : @"NextToken",
             @"policyNames" : @"PolicyNames",
             };
}

@end

@implementation AWSAutoScalingDescribeScalingActivitiesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"activityIds" : @"ActivityIds",
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"maxRecords" : @"MaxRecords",
             @"nextToken" : @"NextToken",
             };
}

@end

@implementation AWSAutoScalingDescribeScheduledActionsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"endTime" : @"EndTime",
             @"maxRecords" : @"MaxRecords",
             @"nextToken" : @"NextToken",
             @"scheduledActionNames" : @"ScheduledActionNames",
             @"startTime" : @"StartTime",
             };
}

+ (NSValueTransformer *)endTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)startTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

@end

@implementation AWSAutoScalingDescribeTagsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"filters" : @"Filters",
             @"maxRecords" : @"MaxRecords",
             @"nextToken" : @"NextToken",
             };
}

+ (NSValueTransformer *)filtersJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingFilter class]];
}

@end

@implementation AWSAutoScalingDescribeTerminationPolicyTypesAnswer

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"terminationPolicyTypes" : @"TerminationPolicyTypes",
             };
}

@end

@implementation AWSAutoScalingDisableMetricsCollectionQuery

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"metrics" : @"Metrics",
             };
}

@end

@implementation AWSAutoScalingEbs

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"deleteOnTermination" : @"DeleteOnTermination",
             @"iops" : @"Iops",
             @"snapshotId" : @"SnapshotId",
             @"volumeSize" : @"VolumeSize",
             @"volumeType" : @"VolumeType",
             };
}

@end

@implementation AWSAutoScalingEnableMetricsCollectionQuery

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"granularity" : @"Granularity",
             @"metrics" : @"Metrics",
             };
}

@end

@implementation AWSAutoScalingEnabledMetric

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"granularity" : @"Granularity",
             @"metric" : @"Metric",
             };
}

@end

@implementation AWSAutoScalingExecutePolicyType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"honorCooldown" : @"HonorCooldown",
             @"policyName" : @"PolicyName",
             };
}

@end

@implementation AWSAutoScalingFilter

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"name" : @"Name",
             @"values" : @"Values",
             };
}

@end

@implementation AWSAutoScalingInstance

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"availabilityZone" : @"AvailabilityZone",
             @"healthStatus" : @"HealthStatus",
             @"instanceId" : @"InstanceId",
             @"launchConfigurationName" : @"LaunchConfigurationName",
             @"lifecycleState" : @"LifecycleState",
             };
}

+ (NSValueTransformer *)lifecycleStateJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSNumber *(NSString *value) {
        if ([value isEqualToString:@"Pending"]) {
            return @(AWSAutoScalingLifecycleStatePending);
        }
        if ([value isEqualToString:@"Quarantined"]) {
            return @(AWSAutoScalingLifecycleStateQuarantined);
        }
        if ([value isEqualToString:@"InService"]) {
            return @(AWSAutoScalingLifecycleStateInService);
        }
        if ([value isEqualToString:@"Terminating"]) {
            return @(AWSAutoScalingLifecycleStateTerminating);
        }
        if ([value isEqualToString:@"Terminated"]) {
            return @(AWSAutoScalingLifecycleStateTerminated);
        }
        return @(AWSAutoScalingLifecycleStateUnknown);
    } reverseBlock:^NSString *(NSNumber *value) {
        switch ([value integerValue]) {
            case AWSAutoScalingLifecycleStatePending:
                return @"Pending";
            case AWSAutoScalingLifecycleStateQuarantined:
                return @"Quarantined";
            case AWSAutoScalingLifecycleStateInService:
                return @"InService";
            case AWSAutoScalingLifecycleStateTerminating:
                return @"Terminating";
            case AWSAutoScalingLifecycleStateTerminated:
                return @"Terminated";
            case AWSAutoScalingLifecycleStateUnknown:
            default:
                return nil;
        }
    }];
}

@end

@implementation AWSAutoScalingInstanceMonitoring

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"enabled" : @"Enabled",
             };
}

@end

@implementation AWSAutoScalingLaunchConfiguration

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"associatePublicIpAddress" : @"AssociatePublicIpAddress",
             @"blockDeviceMappings" : @"BlockDeviceMappings",
             @"createdTime" : @"CreatedTime",
             @"ebsOptimized" : @"EbsOptimized",
             @"iamInstanceProfile" : @"IamInstanceProfile",
             @"imageId" : @"ImageId",
             @"instanceMonitoring" : @"InstanceMonitoring",
             @"instanceType" : @"InstanceType",
             @"kernelId" : @"KernelId",
             @"keyName" : @"KeyName",
             @"launchConfigurationARN" : @"LaunchConfigurationARN",
             @"launchConfigurationName" : @"LaunchConfigurationName",
             @"placementTenancy" : @"PlacementTenancy",
             @"ramdiskId" : @"RamdiskId",
             @"securityGroups" : @"SecurityGroups",
             @"spotPrice" : @"SpotPrice",
             @"userData" : @"UserData",
             };
}

+ (NSValueTransformer *)blockDeviceMappingsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingBlockDeviceMapping class]];
}

+ (NSValueTransformer *)createdTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)instanceMonitoringJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[AWSAutoScalingInstanceMonitoring class]];
}

@end

@implementation AWSAutoScalingLaunchConfigurationNameType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"launchConfigurationName" : @"LaunchConfigurationName",
             };
}

@end

@implementation AWSAutoScalingLaunchConfigurationNamesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"launchConfigurationNames" : @"LaunchConfigurationNames",
             @"maxRecords" : @"MaxRecords",
             @"nextToken" : @"NextToken",
             };
}

@end

@implementation AWSAutoScalingLaunchConfigurationsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"launchConfigurations" : @"LaunchConfigurations",
             @"nextToken" : @"NextToken",
             };
}

+ (NSValueTransformer *)launchConfigurationsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingLaunchConfiguration class]];
}

@end

@implementation AWSAutoScalingMetricCollectionType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"metric" : @"Metric",
             };
}

@end

@implementation AWSAutoScalingMetricGranularityType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"granularity" : @"Granularity",
             };
}

@end

@implementation AWSAutoScalingNotificationConfiguration

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"notificationType" : @"NotificationType",
             @"topicARN" : @"TopicARN",
             };
}

@end

@implementation AWSAutoScalingPoliciesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"nextToken" : @"NextToken",
             @"scalingPolicies" : @"ScalingPolicies",
             };
}

+ (NSValueTransformer *)scalingPoliciesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingScalingPolicy class]];
}

@end

@implementation AWSAutoScalingPolicyARNType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"policyARN" : @"PolicyARN",
             };
}

@end

@implementation AWSAutoScalingProcessType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"processName" : @"ProcessName",
             };
}

@end

@implementation AWSAutoScalingProcessesType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"processes" : @"Processes",
             };
}

+ (NSValueTransformer *)processesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingProcessType class]];
}

@end

@implementation AWSAutoScalingPutNotificationConfigurationType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"notificationTypes" : @"NotificationTypes",
             @"topicARN" : @"TopicARN",
             };
}

@end

@implementation AWSAutoScalingPutScalingPolicyType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"adjustmentType" : @"AdjustmentType",
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"cooldown" : @"Cooldown",
             @"minAdjustmentStep" : @"MinAdjustmentStep",
             @"policyName" : @"PolicyName",
             @"scalingAdjustment" : @"ScalingAdjustment",
             };
}

@end

@implementation AWSAutoScalingPutScheduledUpdateGroupActionType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"desiredCapacity" : @"DesiredCapacity",
             @"endTime" : @"EndTime",
             @"maxSize" : @"MaxSize",
             @"minSize" : @"MinSize",
             @"recurrence" : @"Recurrence",
             @"scheduledActionName" : @"ScheduledActionName",
             @"startTime" : @"StartTime",
             @"time" : @"Time",
             };
}

+ (NSValueTransformer *)endTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)startTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)timeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

@end

@implementation AWSAutoScalingScalingPolicy

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"adjustmentType" : @"AdjustmentType",
             @"alarms" : @"Alarms",
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"cooldown" : @"Cooldown",
             @"minAdjustmentStep" : @"MinAdjustmentStep",
             @"policyARN" : @"PolicyARN",
             @"policyName" : @"PolicyName",
             @"scalingAdjustment" : @"ScalingAdjustment",
             };
}

+ (NSValueTransformer *)alarmsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingAlarm class]];
}

@end

@implementation AWSAutoScalingScalingProcessQuery

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"scalingProcesses" : @"ScalingProcesses",
             };
}

@end

@implementation AWSAutoScalingScheduledActionsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"nextToken" : @"NextToken",
             @"scheduledUpdateGroupActions" : @"ScheduledUpdateGroupActions",
             };
}

+ (NSValueTransformer *)scheduledUpdateGroupActionsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingScheduledUpdateGroupAction class]];
}

@end

@implementation AWSAutoScalingScheduledUpdateGroupAction

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"desiredCapacity" : @"DesiredCapacity",
             @"endTime" : @"EndTime",
             @"maxSize" : @"MaxSize",
             @"minSize" : @"MinSize",
             @"recurrence" : @"Recurrence",
             @"scheduledActionARN" : @"ScheduledActionARN",
             @"scheduledActionName" : @"ScheduledActionName",
             @"startTime" : @"StartTime",
             @"time" : @"Time",
             };
}

+ (NSValueTransformer *)endTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)startTimeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

+ (NSValueTransformer *)timeJSONTransformer {
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *str) {
        return [NSDate az_dateFromString:str];
    } reverseBlock:^id(NSDate *date) {
        return [date az_stringValue:AZDateISO8601DateFormat1];
    }];
}

@end

@implementation AWSAutoScalingSetDesiredCapacityType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"desiredCapacity" : @"DesiredCapacity",
             @"honorCooldown" : @"HonorCooldown",
             };
}

@end

@implementation AWSAutoScalingSetInstanceHealthQuery

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"healthStatus" : @"HealthStatus",
             @"instanceId" : @"InstanceId",
             @"shouldRespectGracePeriod" : @"ShouldRespectGracePeriod",
             };
}

@end

@implementation AWSAutoScalingSuspendedProcess

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"processName" : @"ProcessName",
             @"suspensionReason" : @"SuspensionReason",
             };
}

@end

@implementation AWSAutoScalingTag

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"key" : @"Key",
             @"propagateAtLaunch" : @"PropagateAtLaunch",
             @"resourceId" : @"ResourceId",
             @"resourceType" : @"ResourceType",
             @"value" : @"Value",
             };
}

@end

@implementation AWSAutoScalingTagDescription

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"key" : @"Key",
             @"propagateAtLaunch" : @"PropagateAtLaunch",
             @"resourceId" : @"ResourceId",
             @"resourceType" : @"ResourceType",
             @"value" : @"Value",
             };
}

@end

@implementation AWSAutoScalingTagsType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"nextToken" : @"NextToken",
             @"tags" : @"Tags",
             };
}

+ (NSValueTransformer *)tagsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[AWSAutoScalingTagDescription class]];
}

@end

@implementation AWSAutoScalingTerminateInstanceInAutoScalingGroupType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"instanceId" : @"InstanceId",
             @"shouldDecrementDesiredCapacity" : @"ShouldDecrementDesiredCapacity",
             };
}

@end

@implementation AWSAutoScalingUpdateAutoScalingGroupType

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"autoScalingGroupName" : @"AutoScalingGroupName",
             @"availabilityZones" : @"AvailabilityZones",
             @"defaultCooldown" : @"DefaultCooldown",
             @"desiredCapacity" : @"DesiredCapacity",
             @"healthCheckGracePeriod" : @"HealthCheckGracePeriod",
             @"healthCheckType" : @"HealthCheckType",
             @"launchConfigurationName" : @"LaunchConfigurationName",
             @"maxSize" : @"MaxSize",
             @"minSize" : @"MinSize",
             @"placementGroup" : @"PlacementGroup",
             @"terminationPolicies" : @"TerminationPolicies",
             @"VPCZoneIdentifier" : @"VPCZoneIdentifier",
             };
}

@end
