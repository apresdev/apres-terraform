package test

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"slices"
	"strings"
	"testing"
	"time"

	"apres.dev/awstagging"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/lambda"
	lambdaTypes "github.com/aws/aws-sdk-go-v2/service/lambda/types"
	"github.com/aws/aws-sdk-go-v2/service/rds"
	rdsTypes "github.com/aws/aws-sdk-go-v2/service/rds/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"
)

type RdsTestSuite struct {
	suite.Suite
	ctx          context.Context
	awsRegion    string
	environment  string
	namePrefix   string
	rdsClient    *rds.Client
	lambdaClient *lambda.Client
	dbName       string
	dbUser       string
	doNotDestroy bool
	vpcEnvTag    string
}

type Outputs struct {
	Endpoint           string
	Username           string
	PasswordARN        string
	ClusterId          string
	Port               string
	LambdaFunctionARN  string
	LambdaFunctionName string
}

func getOutputs(t *testing.T, terraformOptions *terraform.Options) Outputs {
	return Outputs{
		Endpoint:           terraform.Output(t, terraformOptions, "endpoint"),
		PasswordARN:        terraform.Output(t, terraformOptions, "master_password_secret_arn"),
		ClusterId:          terraform.Output(t, terraformOptions, "cluster_id"),
		Port:               terraform.Output(t, terraformOptions, "port"),
		LambdaFunctionARN:  terraform.Output(t, terraformOptions, "lambda_function_arn"),
		LambdaFunctionName: terraform.Output(t, terraformOptions, "lambda_function_name"),
	}
}

func TestRdsTestSuite(t *testing.T) {
	suite.Run(t, new(RdsTestSuite))
}

func (s *RdsTestSuite) SetupSuite() {
	s.ctx = context.Background()
	s.awsRegion = "us-east-2"
	s.environment = "Test"
	if os.Getenv("TESTING_DO_NOT_DESTROY") == "true" {
		// use a static name
		s.namePrefix = "test"
	} else {
		// use the timestamp as a name so it's always unique.
		now := time.Now().Unix()
		s.namePrefix = fmt.Sprintf("test%d", now)
	}
	s.dbName = "asdf"
	s.dbUser = "rootuser"

	// Do not configure AWS creds here, we want that per test suite.
	if os.Getenv("TESTING_DO_NOT_DESTROY") == "true" {
		s.doNotDestroy = true
	} else {
		s.doNotDestroy = false
	}
	// Get the vpc tag, emtpy string is fine.
	s.vpcEnvTag = os.Getenv("TESTING_VPC_ENV_TAG")

	// create AWS creds before each test
	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")

	// Configure the AWS client for STS, RDS and Lambda
	s.rdsClient = rds.NewFromConfig(cfg)
	s.lambdaClient = lambda.NewFromConfig(cfg)
}

// TestAuroraMySQL tests Aurora MySQL, configured with serverless, and adds an
// innocous cluster parameter to test that path.
func (s *RdsTestSuite) TestAuroraMySQL() {
	var engine = "aurora-mysql"
	var engineVersion = "8.0.mysql_aurora.3.08.0"
	var preferredMaintenanceWindow = "sun:08:00-sun:08:30"
	var preferredBackupWindow = "07:00-07:30"
	var name = fmt.Sprintf("%s-mysql", s.namePrefix)
	// we're going to set an innocous cluster parameter to verify it's set. max_error_count
	// is the one, default is 1024 so we'll bump it.
	// https://dev.mysql.com/doc/refman/8.4/en/server-system-variables.html#sysvar_max_error_count
	var paramName = "max_error_count"
	var maxErrorCount = "2048" // gotta pass in a string
	var dbParams = []interface{}{
		map[string]string{
			"name":  paramName,
			"value": maxErrorCount,
		},
	}
	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures",
		Vars: map[string]interface{}{
			"name":                      name,
			"environment":               s.environment,
			"engine":                    engine,
			"engine_version":            engineVersion,
			"db_parameter_group_family": "aurora-mysql8.0",
			"serverless":                true,
			"backup_window":             preferredBackupWindow,
			"maintenance_window":        preferredMaintenanceWindow,
			"database_name":             s.dbName,
			"master_username":           s.dbUser,
			"db_cluster_parameters":     dbParams,
		},
	}
	if s.vpcEnvTag != "" {
		terraformOptions.Vars["vpc_environment_tag"] = s.vpcEnvTag
	}
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	if ! s.doNotDestroy {
	  defer terraform.Destroy(s.T(), terraformOptions)
	}

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	outputs := getOutputs(s.T(), terraformOptions)

	clusters, err := s.rdsClient.DescribeDBClusters(s.ctx, &rds.DescribeDBClustersInput{
		DBClusterIdentifier: &outputs.ClusterId})
	s.Require().NoError(err, "expected no error for DescribeDBClusters")
	s.Require().NotEmpty(clusters.DBClusters, "expected DBClusters to be non-empty")
	s.Require().Equal(1, len(clusters.DBClusters), "expected exactly one DBCluster")
	cluster := clusters.DBClusters[0]

	checkCommonClusterAttributes(s, &cluster, engine, engineVersion, preferredBackupWindow, preferredMaintenanceWindow)

	s.Require().True(slices.Equal(cluster.EnabledCloudwatchLogsExports, []string{"audit", "error", "general", "slowquery"}), "expected EnabledCloudwatchLogsExports to match")

	// serverless v2 scaling
	s.Require().Equal(float64(0), *cluster.ServerlessV2ScalingConfiguration.MinCapacity, "expected MinCapacity to be 0")
	s.Require().Equal(float64(2), *cluster.ServerlessV2ScalingConfiguration.MaxCapacity, "expected MaxCapacity to be 2")
	s.Require().Equal(int32(300), *cluster.ServerlessV2ScalingConfiguration.SecondsUntilAutoPause, "expected SecondsUntilAutoPause to be 300")

	// backtrack is mysql only
	s.Require().Equal(int64(21600), *cluster.BacktrackWindow, "expected BacktrackWindow to be 21600")

	// check tags
	checkTags(s, &cluster)

	// check the cluster parameter group. We know the name has the -cluster appended, and is lower case
	paramGroupName := fmt.Sprintf("%s-%s-cluster", strings.ToLower(s.environment), strings.ToLower(name))
	n := "parameter-name"
	paramGroups, err := s.rdsClient.DescribeDBClusterParameters(s.ctx,
		&rds.DescribeDBClusterParametersInput{
			DBClusterParameterGroupName: &paramGroupName,
			Filters: []rdsTypes.Filter{
				{
					Name:   &n,
					Values: []string{paramName},
				},
			},
		})
	s.Require().NoError(err, "expected no error for DescribeDBClusterParameterGroups")
	s.Require().True(len(paramGroups.Parameters) > 0, "expected Parameters to be non-empty")
	found := false
	for _, param := range paramGroups.Parameters {
		if *param.ParameterName == paramName {
			found = true
			s.Require().Equal("2048", *param.ParameterValue, "expected ParameterValue to match")
		}
	}
	s.Require().True(found, "expected ParameterName %s to be found, it was not", paramName)

	// Invoke the Lambda we created, which checks for DB connectivity
	invokeLambda(s, outputs.LambdaFunctionName)
}

// TestAuroraPostgresSQL tests Aurora PosgreSQL, configured with a db.t3.medium,
// and adds an innocous instance parameter to test that path.
func (s *RdsTestSuite) TestAuroraPostgreSQL() {
	var name = fmt.Sprintf("%s-pgsql", s.namePrefix)
	var engine = "aurora-postgresql"
	var engineVersion = "16.6"
	var preferredMaintenanceWindow = "sun:08:00-sun:08:30"
	var preferredBackupWindow = "07:00-07:30"
	// set an innocuous instance parameter to verify it's set. log_error_verbosity is the one.
	var paramName = "log_error_verbosity"
	var logVerbosity = "VERBOSE"
	var dbParams = []interface{}{
		map[string]string{
			"name":  paramName,
			"value": logVerbosity,
		},
	}
	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures",
		Vars: map[string]interface{}{
			"name":                      name,
			"environment":               s.environment,
			"engine":                    engine,
			"engine_version":            engineVersion,
			"db_parameter_group_family": "aurora-postgresql16",
			"serverless":                false,
			"instance_class":            "db.t3.medium",
			"backup_window":             preferredBackupWindow,
			"maintenance_window":        preferredMaintenanceWindow,
			"database_name":             s.dbName,
			"master_username":           s.dbUser,
			"db_instance_parameters":    dbParams,
		},
	}
	if s.vpcEnvTag != "" {
		terraformOptions.Vars["vpc_environment_tag"] = s.vpcEnvTag
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	if ! s.doNotDestroy {
	  defer terraform.Destroy(s.T(), terraformOptions)
	}

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), terraformOptions)

	outputs := getOutputs(s.T(), terraformOptions)

	clusters, err := s.rdsClient.DescribeDBClusters(s.ctx, &rds.DescribeDBClustersInput{
		DBClusterIdentifier: &outputs.ClusterId})
	s.Require().NoError(err, "expected no error for DescribeDBClusters")
	s.Require().NotEmpty(clusters.DBClusters, "expected DBClusters to be non-empty")
	s.Require().Equal(1, len(clusters.DBClusters), "expected exactly one DBCluster")
	cluster := clusters.DBClusters[0]

	checkCommonClusterAttributes(s, &cluster, engine, engineVersion, preferredBackupWindow, preferredMaintenanceWindow)

	// logging is specific to the db engine
	s.Require().True(slices.Equal(cluster.EnabledCloudwatchLogsExports, []string{"postgresql"}), "expected EnabledCloudwatchLogsExports to match")

	// check tags
	checkTags(s, &cluster)

	// check the cluster parameter group. We know the name has the -instance appended, and is in lower case.
	paramGroupName := fmt.Sprintf("%s-%s-instance", strings.ToLower(s.environment), strings.ToLower(name))
	n := "parameter-name"
	paramGroups, err := s.rdsClient.DescribeDBParameters(s.ctx,
		&rds.DescribeDBParametersInput{
			DBParameterGroupName: &paramGroupName,
			Filters: []rdsTypes.Filter{
				{
					Name:   &n,
					Values: []string{paramName},
				},
			},
		})
	s.Require().NoError(err, "expected no error for DescribeDBParameterGroups")
	s.Require().True(len(paramGroups.Parameters) > 0, "expected Parameters to be non-empty")
	found := false
	for _, param := range paramGroups.Parameters {
		if *param.ParameterName == paramName {
			found = true
			s.Require().Equal(logVerbosity, *param.ParameterValue, "expected ParameterValue to match")
		}
	}
	s.Require().True(found, "expected ParameterName %s to be found, it was not", paramName)

	// Invoke the Lambda we created, which checks for DB connectivity
	invokeLambda(s, outputs.LambdaFunctionName)
}

func invokeLambda(s *RdsTestSuite, lambdaFunctionName string) {
	payload, err := json.Marshal(map[string]interface{}{})
	s.Require().NoError(err, "expected no error for json.Marshal")
	invokeOutput, err := s.lambdaClient.Invoke(s.ctx, &lambda.InvokeInput{
		FunctionName: aws.String(lambdaFunctionName),
		LogType:      lambdaTypes.LogTypeTail,
		Payload:      payload,
	})
	s.Require().NoError(err, "expected no error for Invoke")
	s.T().Log(invokeOutput.LogResult)
	s.Require().Equal(int32(200), invokeOutput.StatusCode, "expected StatusCode to be 200")
	s.Require().Empty(invokeOutput.FunctionError, "expected no error for Lambda function")
}

func checkTags(s *RdsTestSuite, cluster *rdsTypes.DBCluster) {
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range cluster.TagList {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Require().True(valid, fmt.Sprintf("Expected tags not found: %v", missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Require().True(valid, fmt.Sprintf("Tags have invalid values: %v", bad))
}

func checkCommonClusterAttributes(s *RdsTestSuite, cluster *rdsTypes.DBCluster, engine string, engineVersion string, preferredBackupWindow string, preferredMaintenanceWindow string) {
	s.Require().Equal(int32(7), *cluster.BackupRetentionPeriod, "expected BackupRetentionPeriod to be 7")
	s.Require().True(*cluster.CopyTagsToSnapshot, "expected CopyTagsToSnapshot to be true")
	s.Require().False(*cluster.DeletionProtection, "expected DeletionProtection to be false")
	s.Require().Equal(engine, *cluster.Engine, "expected Engine to match")
	s.Require().Equal(engineVersion, *cluster.EngineVersion, "expected EngineVersion to match")
	s.Require().Equal(s.dbUser, *cluster.MasterUsername, "expected MasterUsername to match")
	s.Require().True(*cluster.PerformanceInsightsEnabled, "expected PerformanceInsightsEnabled to be true")
	s.Require().Equal(preferredBackupWindow, *cluster.PreferredBackupWindow, "expected PreferredBackupWindow to match")
	s.Require().Equal(preferredMaintenanceWindow, *cluster.PreferredMaintenanceWindow, "expected PreferredMaintenanceWindow to match")
}
