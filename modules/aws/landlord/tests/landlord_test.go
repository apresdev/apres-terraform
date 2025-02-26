package test

import (
	"context"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/suite"
)

type LandlordTestSuite struct {
	suite.Suite
	ctx              context.Context
	terraformOptions *terraform.Options
}

func TestLandlordTestSuite(t *testing.T) {
	suite.Run(t, new(LandlordTestSuite))
}

func (s *LandlordTestSuite) SetupSuite() {
	s.ctx = context.Background()
}

func (s *LandlordTestSuite) TestPlaceholder() {
	s.Assert().True(true, "This is a placeholder test for later.")
}
