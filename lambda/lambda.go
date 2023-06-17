/*
Purpose - This lambda code generate random string and update the header field values of ALB Forwarding
		  Rule and CloudFront config. The generated Random string will be stored in the SecretManager
Developer- K.Janarthanan
Date - 11/6/2023
*/
package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudfront"
	"github.com/aws/aws-sdk-go/service/elbv2"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
)

const (
	letterBytes = "abcdefghijklmnopqrstuvwxyz"
	wordCount   = 10
	minWordLen  = 3
	maxWordLen  = 5
)

//Generate Random string
func generateRandomString() string {
	rand.Seed(time.Now().UnixNano())

	var words []string
	for i := 0; i < wordCount; i++ {
		wordLen := rand.Intn(maxWordLen-minWordLen+1) + minWordLen
		word := make([]byte, wordLen)
		for j := range word {
			word[j] = letterBytes[rand.Intn(len(letterBytes))]
		}
		words = append(words, string(word))
	}

	return strings.Join(words, "")
}

//Modify the ALB
func modify_alb(headervalue string) error {

	fmt.Println("Going to modify the ALB Headers")

	// create an ELBv2 client with an AWS session
	// Create a session with the desired region
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(os.Getenv("AWS_REGION")), // Replace with your desired region
	})
	if err != nil {
		return err
	}

	svc := elbv2.New(sess)

	input := &elbv2.ModifyRuleInput{

		Conditions: []*elbv2.RuleCondition{
			{
				Field: aws.String("http-header"),
				HttpHeaderConfig: &elbv2.HttpHeaderConditionConfig{
					HttpHeaderName: aws.String(os.Getenv("HEADER_NAME")),
					Values: []*string{
						aws.String(headervalue),
					},
				},
			},
		},

		//Action
		Actions: []*elbv2.Action{
			{
				Type:           aws.String("forward"),                     // Specify the action type (e.g., "forward" for forwarding to a target group)
				TargetGroupArn: aws.String(os.Getenv("TARGET_GROUP_ARN")), // Replace with your target group ARN
			},
		},
		RuleArn: aws.String(os.Getenv("LISTENER_RULE_ARN")),
	}
	_, err = svc.ModifyRule(input)

	if err != nil {
		fmt.Println("Error while updating ALB Rule:", err)
		return err
	}

	// return a success message
	fmt.Println("Listener rule modified successfully")

	return nil
}

//Modify the Cloudront Config
func modify_cloudfront(headervalue string) error {

	//Get the distribution config
	//Update the distribution config

	fmt.Println("Going to retrieve the CloudFront Config")

	// Create a session with the desired region
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(os.Getenv("AWS_REGION")), // Replace with your desired region
	})
	if err != nil {
		return err
	}
	svc := cloudfront.New(sess)

	input := &cloudfront.GetDistributionConfigInput{
		Id: aws.String(os.Getenv("DISTRIBUTION_ID")),
	}

	result, err := svc.GetDistributionConfig(input)

	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case cloudfront.ErrCodeNoSuchDistribution:
				fmt.Println(cloudfront.ErrCodeNoSuchDistribution, aerr.Error())
			case cloudfront.ErrCodeAccessDenied:
				fmt.Println(cloudfront.ErrCodeAccessDenied, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			fmt.Println(err.Error())
		}
		fmt.Println("Error while getting CloudFront Config :", err)
		return err
	}

	var payload *cloudfront.GetDistributionConfigOutput //Return payload is type of this
	payload = result

	fmt.Println("CloudFront Data modification is completed")
	fmt.Println("Going to update the Cloudfront Config")

	// Update the existing CustomHeaders with your new header
	customHeaders := &cloudfront.CustomHeaders{
		Quantity: aws.Int64(1), // Assuming you have only one custom header
		Items: []*cloudfront.OriginCustomHeader{
			{
				HeaderName:  aws.String(os.Getenv("HEADER_NAME")),
				HeaderValue: aws.String(headervalue),
			},
		},
	}

	if len(payload.DistributionConfig.Origins.Items) > 0 {
		payload.DistributionConfig.Origins.Items[0].CustomHeaders = customHeaders
		fmt.Println("Modified the customHeader in CloudFront")
	} else {
		fmt.Println("Did not Modified the customHeader in CloudFront")
	}

	input_update := &cloudfront.UpdateDistributionInput{
		Id:                 aws.String(os.Getenv("DISTRIBUTION_ID")),
		DistributionConfig: payload.DistributionConfig,
		IfMatch:            payload.ETag,
	}

	_, err = svc.UpdateDistribution(input_update)

	if err != nil {
		fmt.Println("Error while updating the CloudFront Config:", err)
		return err
	}

	fmt.Println("CloudFront configuration modified successfully")
	return nil
}

func update_secret(headervalue string) error {

	fmt.Println("Going to update the secret manager")

	// Create a session with the desired region
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(os.Getenv("AWS_REGION")), // Replace with your desired region
	})
	if err != nil {
		return err
	}

	// Create the Secrets Manager service client
	svc := secretsmanager.New(sess)

	//Define the SM input
	input := &secretsmanager.UpdateSecretInput{
		SecretId:     aws.String(os.Getenv("AWS_SECRET_ID")),
		SecretString: aws.String(headervalue),
	}

	_, err = svc.UpdateSecret(input)

	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case secretsmanager.ErrCodeInvalidParameterException:
				fmt.Println(secretsmanager.ErrCodeInvalidParameterException, aerr.Error())
			case secretsmanager.ErrCodeInvalidRequestException:
				fmt.Println(secretsmanager.ErrCodeInvalidRequestException, aerr.Error())
			case secretsmanager.ErrCodeLimitExceededException:
				fmt.Println(secretsmanager.ErrCodeLimitExceededException, aerr.Error())
			case secretsmanager.ErrCodeEncryptionFailure:
				fmt.Println(secretsmanager.ErrCodeEncryptionFailure, aerr.Error())
			case secretsmanager.ErrCodeResourceExistsException:
				fmt.Println(secretsmanager.ErrCodeResourceExistsException, aerr.Error())
			case secretsmanager.ErrCodeResourceNotFoundException:
				fmt.Println(secretsmanager.ErrCodeResourceNotFoundException, aerr.Error())
			case secretsmanager.ErrCodeMalformedPolicyDocumentException:
				fmt.Println(secretsmanager.ErrCodeMalformedPolicyDocumentException, aerr.Error())
			case secretsmanager.ErrCodeInternalServiceError:
				fmt.Println(secretsmanager.ErrCodeInternalServiceError, aerr.Error())
			case secretsmanager.ErrCodePreconditionNotMetException:
				fmt.Println(secretsmanager.ErrCodePreconditionNotMetException, aerr.Error())
			case secretsmanager.ErrCodeDecryptionFailure:
				fmt.Println(secretsmanager.ErrCodeDecryptionFailure, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
		return err
	}

	fmt.Println("Secret Manager is updated successfully")

	return nil
}

func handler(ctx context.Context) error {

	randomString := generateRandomString()

	//Modify ALB Rules
	err := modify_alb(randomString)
	if err != nil {
		fmt.Println("Error in main:", err)
		return err
	}

	//Modify the Cloudfront Config
	err = modify_cloudfront(randomString)
	if err != nil {
		fmt.Println("Error in main:", err)
		return err
	}

	err = update_secret(randomString)
	if err != nil {
		fmt.Println("Error in main:", err)
		return err
	}

	return nil
}

func main() {
	lambda.Start(handler)
}
