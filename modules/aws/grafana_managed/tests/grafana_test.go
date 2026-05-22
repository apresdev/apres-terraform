package test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/grafana"
	grafanaTypes "github.com/aws/aws-sdk-go-v2/service/grafana/types"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
	ssmTypes "github.com/aws/aws-sdk-go-v2/service/ssm/types"
	"github.com/go-openapi/strfmt"
	goapi "github.com/grafana/grafana-openapi-client-go/client"
	"github.com/grafana/grafana-openapi-client-go/client/folders"
	"github.com/grafana/grafana-openapi-client-go/client/provisioning"
	"github.com/grafana/grafana-openapi-client-go/client/search"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"

	"apres.dev/awstagging"
)

type GrafanaTestSuite struct {
	suite.Suite
	ctx              context.Context
	grafanaAPI       *goapi.GrafanaHTTPAPI
	name             string
	awsRegion        string
	environment      string
	awsConfig        aws.Config
	accounts         map[string]string
	grafanaURL       string
	grafanaARN       string
	grafanaVersion   string
	snsTopicARN      string
	terraformOptions *terraform.Options
	setupDone        bool
}

func TestGrafanaTestSuite(t *testing.T) {
	suite.Run(t, new(GrafanaTestSuite))
}

func (s *GrafanaTestSuite) TearDownSuite() {
	defer terraform.Destroy(s.T(), s.terraformOptions)
}

func (s *GrafanaTestSuite) SetupSuite() {
	// if the terraform deploy fails, the test suite exits and the TearDownSuite is never called. One
	// alternative is to use SetupTest/TearDownTest but that means the stack is created/destroyed for
	// each test, which is slow and very expensive. So instead we use this, inspired by
	// https://github.com/stretchr/testify/issues/1123
	defer func() {
		if !s.setupDone {
			terraform.Destroy(s.T(), s.terraformOptions)
		}
	}()

	s.ctx = context.Background()
	s.awsRegion = "us-east-2"
	now := time.Now().Unix()
	s.environment = fmt.Sprintf("Test%d", now)
	s.name = "Grafana"

	cfg, err := config.LoadDefaultConfig(s.ctx, config.WithRegion(s.awsRegion))
	s.Require().NoError(err, "expected no error for LoadDefaultConfig creating AWS session")
	s.awsConfig = cfg
	s.accounts = map[string]string{
		"Test": "111111111111",
		"Dev":  "222222222222",
		//"Sandbox": "333333333333",
	}
	s.terraformOptions = &terraform.Options{
		TerraformDir: "./fixtures",
		Vars: map[string]any{
			"name":                         s.name,
			"environment":                  s.environment,
			"accounts":                     s.accounts,
			"admin_groups":                 []string{"31db85b0-4031-705e-d39b-ce16bcae5a59"},
			"regions":                      []string{"us-east-2", "us-west-2"},
			"custom_dashboard_folder_name": "Custom",
		},
	}

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(s.T(), s.terraformOptions)
	s.grafanaURL = terraform.Output(s.T(), s.terraformOptions, "grafana_url")
	s.grafanaARN = terraform.Output(s.T(), s.terraformOptions, "grafana_arn")
	s.grafanaVersion = terraform.Output(s.T(), s.terraformOptions, "grafana_version")
	s.snsTopicARN = terraform.Output(s.T(), s.terraformOptions, "notifications_sns_topic_arn")

	// get API token from SSM, required for the grafana client
	token, err := s.getAuthTokenFromSSM()
	s.Require().NoError(err, "expected no error for getAuthTokenFromSSM")

	// Create a Grafana client
	s.createGrafanaClient(token, s.grafanaURL)

	// Mark as done so the defer func doesn't destroy the stack
	s.setupDone = true
}

func (s *GrafanaTestSuite) TestSSMConfig() {
	// check SSM tags
	ssmClient := ssm.NewFromConfig(s.awsConfig)
	tagsResp, err := ssmClient.ListTagsForResource(s.ctx, &ssm.ListTagsForResourceInput{
		ResourceId:   aws.String(s.ssmParameterName()),
		ResourceType: ssmTypes.ResourceTypeForTaggingParameter,
	})
	s.Require().NoError(err, "expected no error for ListTagsForResource")
	tags := make([]awstagging.TagItem, 0)
	for _, tag := range tagsResp.TagList {
		tags = append(tags, awstagging.TagItem{Key: tag.Key, Value: tag.Value})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Assert().True(valid, fmt.Sprintf("Expected tags not found for SSM Parameter %s: %v", s.ssmParameterName(), missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Assert().True(valid, fmt.Sprintf("Tags have invalid values for SSM parameter %s: %v", s.ssmParameterName(), bad))
}

// TestSNSConfig checks that the SNS topic exists, using the display name
// as verification.
func (s *GrafanaTestSuite) TestSNSConfig() {
	snsClient := sns.NewFromConfig(s.awsConfig)
	resp, err := snsClient.GetTopicAttributes(s.ctx, &sns.GetTopicAttributesInput{
		TopicArn: aws.String(s.snsTopicARN),
	})
	s.Assert().NoError(err, "expected no error for GetTopicAttributes")
	expect := fmt.Sprintf("%s-%s-alerts", s.environment, s.name)
	s.Assert().Equal(expect, resp.Attributes["DisplayName"], "expected DisplayName to be '%s'", expect)
}

// TestManagedGrafana checks that the Grafana instance was created with the correct version,
// using the AWS APIs
func (s *GrafanaTestSuite) TestManagedGrafana() {
	s.Assert().Equal("10.4", s.grafanaVersion)

	// check tags
	grafanaClient := grafana.NewFromConfig(s.awsConfig)
	resp, err := grafanaClient.ListTagsForResource(s.ctx, &grafana.ListTagsForResourceInput{
		ResourceArn: aws.String(s.grafanaARN),
	})
	s.Require().NoError(err, "expected no error for ListTagsForResource")
	tags := make([]awstagging.TagItem, 0)
	for k, v := range resp.Tags {
		tags = append(tags, awstagging.TagItem{Key: aws.String(k), Value: aws.String(v)})
	}
	valid, missing := awstagging.VerifyTagsExist(tags)
	s.Assert().True(valid, fmt.Sprintf("Expected tags not found for Grafana Instance %s: %v", s.grafanaARN, missing))

	valid, bad := awstagging.VerifyTagsValueFormat(tags)
	s.Assert().True(valid, fmt.Sprintf("Tags have invalid values for Grafana Instance %s: %v", s.grafanaARN, bad))

	// annoyingly we don't get the ID from the terraform provider, but it's the first element in the URL.
	u, err := url.Parse(s.grafanaURL)
	s.Assert().NoError(err, "expected no error for parse API url")
	workspaceID := strings.Split(u.Host, ".")[0]

	authResp, err := grafanaClient.DescribeWorkspaceAuthentication(s.ctx, &grafana.DescribeWorkspaceAuthenticationInput{
		WorkspaceId: aws.String(workspaceID),
	})
	s.Require().NoError(err, "expected no error for DescribeWorkspaceAuthentication")
	auth := authResp.Authentication
	s.Assert().Len(auth.Providers, 1, "expected only one authentication provider")
	s.Assert().Equal(grafanaTypes.AuthenticationProviderTypesAwsSso, auth.Providers[0], "expected AWS SSO authentication provider")

}

// TestGrafanaDashboards checks that the dashboards were created in the correct folder
func (s *GrafanaTestSuite) TestGrafanaDashboards() {
	folderUID, err := s.getFolderUID("Apres")
	s.Assert().NoError(err, "expected no error for getFolderUID")
	s.Assert().NotEmpty(folderUID, "expected folder UID to be non-empty")

	// Load dashboard titles from JSON files
	titlesFound := make(map[string]bool, 0)
	for _, dashboard := range s.getDashboardTitles() {
		titlesFound[dashboard] = false
	}
	// check if the dashboards are created in the folder we care about.
	params := search.SearchParams{}
	params.FolderUIDs = []string{folderUID}
	searchOk, err := s.grafanaAPI.Search.Search(&params)
	s.Assert().NoError(err, "expected no error for search")
	s.Assert().NotNil(searchOk, "expected search response")
	s.Assert().GreaterOrEqual(len(titlesFound), len(searchOk.Payload), "expected at least 2 dashboards")

	// Loop through search results, check if the title is there, mark it as found.
	for _, dashboard := range searchOk.Payload {
		if _, ok := titlesFound[dashboard.Title]; ok {
			titlesFound[dashboard.Title] = true
		}
	}
	for title, found := range titlesFound {
		s.Assert().True(found, "expected dashboard %s to be found, titlesFound: %v", title, titlesFound)
	}

}

// TestGrafanaDataSources checks that the data sources were created for each account
func (s *GrafanaTestSuite) TestGrafanaDataSources() {
	// check data sources, should be one for each account
	dsFound := make(map[string]bool, 0)
	for k, v := range s.accounts {
		name := fmt.Sprintf("%s (%s)", k, v)
		dsFound[name] = false
	}
	ds, err := s.grafanaAPI.Datasources.GetDataSources()
	s.Assert().NoError(err, "expected no error for GetDataSources")
	for _, ds := range ds.Payload {
		if ds.Type == "cloudwatch" {
			if _, ok := dsFound[ds.Name]; ok {
				dsFound[ds.Name] = true
			}
		}
	}
	for name, found := range dsFound {
		s.Assert().True(found, "expected data source %s to be found", name)
	}
}

// TestGrafanaAlertContactPoint checks that the default SNS contact point was created
func (s *GrafanaTestSuite) TestGrafanaAlertContactPoint() {
	// We can't look for the contact point by name, we'll get a 500 error and no way to
	// differentiate between a 4xx and 5xx error. So we'll just get all of them and look for the name.
	defaultName := "Default SNS Contact Point"
	resp, err := s.grafanaAPI.Provisioning.GetContactpoints(&provisioning.GetContactpointsParams{})
	s.Assert().NoError(err, "expected no error for GetContactpoints")
	found := false
	for _, cp := range resp.Payload {
		if cp.Name == defaultName {
			found = true
			break
		}
	}
	s.Assert().True(found, "expected contact point %s to be found", defaultName)
}

// TestGrafanaAlerts checks that the cloudwathch_alarm created in the fixture
// was configurated correctly
func (s *GrafanaTestSuite) TestGrafanaAlerts() {
	alarmPrefix := fmt.Sprintf("%s-%s-SEV1", s.environment, s.name)
	body, err := s.grafanaAPI.Provisioning.GetAlertRules()
	s.Assert().NoError(err, "expected no error for GetAlertRules")
	// The provisioned alerts created by the configurator will have the labels
	// "source: apres_cloudwatch_alarm_module" and "author: configurator" set. There may be
	// alerts defined that are from other stacks, so compare the prefix to find the
	// alert with the unique environment.
	for _, alert := range body.Payload {
		author, authOk := alert.Labels["author"]
		source, srcOk := alert.Labels["source"]
		if authOk && srcOk && strings.Compare(author, "configurator") == 0 && strings.Compare(source, "apres_cloudwatch_alarm_module") == 0 {
			// This is one from the Configurator. Is it ours?
			if strings.HasPrefix(*alert.Title, alarmPrefix) {
				// Found it!
				s.Assert().Contains(alert.Labels, "account-name", "expected account-name label")
				s.Assert().Contains(alert.Labels, "account-id", "expected account-id label")
				s.Assert().Contains(alert.Labels, "region", "expected region label")
				s.Assert().Contains(alert.Labels, "region", "expected region label")
				s.Assert().Contains(alert.Labels, "severity", "expected severity label")
				s.Assert().Contains(alert.Annotations, "runbook_url", "expected runbook_url annotation")
				s.Assert().Equal("https://runbook.example.com", alert.Annotations["runbook_url"], "expected runbook_url annotation")
				s.Assert().Len(alert.Data, 3, "expected 3 data query elements")
				return
			}
		}
	}
	s.Fail(fmt.Sprintf("expected alert with prefix '%s' to be found", alarmPrefix))
}

// getDashboardTitles reads the JSON files in the dashboards directory and returns the titles of the dashboards.
func (s *GrafanaTestSuite) getDashboardTitles() []string {
	dashboardDir := "../dashboards"
	files, err := os.ReadDir(dashboardDir)
	s.Assert().NoError(err, "expected no error for read dashboards directory %s", dashboardDir)

	var titles []string
	for _, file := range files {
		if file.IsDir() || !strings.HasSuffix(file.Name(), ".json") {
			continue
		}

		filePath := fmt.Sprintf("%s/%s", dashboardDir, file.Name())
		content, err := os.ReadFile(filePath)
		s.Assert().NoError(err, "expected no error for read file %s", filePath)

		var dashboard map[string]interface{}
		err = json.Unmarshal(content, &dashboard)
		s.Assert().NoError(err, "expected no error for unmarshal JSON from file %s", filePath)

		if title, ok := dashboard["title"].(string); ok {
			titles = append(titles, title)
		}
	}

	return titles
}

// getFolderUID returns the UID of the folder with the given prefix.
func (s *GrafanaTestSuite) getFolderUID(prefix string) (string, error) {
	// Get list of folders
	folderParams := folders.GetFoldersParams{}
	folders, err := s.grafanaAPI.Folders.GetFolders(&folderParams)
	if err != nil {
		return "", err
	}
	if folders.Payload != nil {
		for _, folder := range folders.Payload {
			if folder.Title == prefix {
				return folder.UID, nil
			}
		}
	}
	return "", fmt.Errorf("folder not found")
}

// ssmParameterName returns the name of the SSM parameter that stores the Grafana API token.
func (s *GrafanaTestSuite) ssmParameterName() string {
	return fmt.Sprintf("/apres/grafana/%s-%s-config", s.environment, s.name)
}

// getAuthTokenFromSSM retrieves the Grafana API token from SSM.
func (s *GrafanaTestSuite) getAuthTokenFromSSM() (authToken *string, err error) {
	ssmClient := ssm.NewFromConfig(s.awsConfig)

	paramName := s.ssmParameterName()
	paramsOutput, err := ssmClient.GetParameter(s.ctx, &ssm.GetParameterInput{
		Name:           aws.String(paramName),
		WithDecryption: aws.Bool(true),
	})
	if err != nil {
		return nil, fmt.Errorf("could not get SSM parameter for ARN %s, %w", paramName, err)
	}
	return paramsOutput.Parameter.Value, nil
}

// createGrafanaClient creates a Grafana client using the given API token and URL.
func (s *GrafanaTestSuite) createGrafanaClient(authToken *string, grafanaURL string) {
	u, err := url.Parse(grafanaURL)
	s.Assert().NoError(err, "expected no error for parse API url")
	transportConfig := goapi.TransportConfig{
		Host:     u.Host,
		BasePath: "/api",
		Schemes:  []string{u.Scheme},
		APIKey:   *authToken,
	}

	s.grafanaAPI = goapi.NewHTTPClientWithConfig(strfmt.Default, &transportConfig)
}
