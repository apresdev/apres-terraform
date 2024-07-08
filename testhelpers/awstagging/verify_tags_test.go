package awstagging_test

import (
	"testing"

	"apres.dev/awstagging"
	"github.com/stretchr/testify/assert"
)

func TestVerifyTagsExist(t *testing.T) {
	appKey := "application"
	compKey := "component"
	envKey := "environment"
	nameKey := "Name"
	ownerKey := "owner"
	managedByKey := "managed-by"
	goodVal := "UnitTest"
	badVal := "unitTest"
	goodNameTag := "Asfd-_ 2134"
	badNameTag := "Asfd-_ 2134$"

	tags := []awstagging.TagItem{}
	valid, missing := awstagging.VerifyTagsExist(tags)
	assert.False(t, valid)
	assert.Len(t, missing, 6)

	tags = append(tags, awstagging.TagItem{Key: &appKey, Value: &goodVal})
	valid, missing = awstagging.VerifyTagsExist(tags)
	assert.False(t, valid)
	assert.Len(t, missing, 5)

	tags = append(tags, awstagging.TagItem{Key: &compKey, Value: &goodVal})
	valid, missing = awstagging.VerifyTagsExist(tags)
	assert.False(t, valid)
	assert.Len(t, missing, 4)

	tags = append(tags, awstagging.TagItem{Key: &envKey, Value: &goodVal})
	valid, missing = awstagging.VerifyTagsExist(tags)
	assert.False(t, valid)
	assert.Len(t, missing, 3)

	tags = append(tags, awstagging.TagItem{Key: &nameKey, Value: &goodVal})
	valid, missing = awstagging.VerifyTagsExist(tags)
	assert.False(t, valid)
	assert.Len(t, missing, 2)

	tags = append(tags, awstagging.TagItem{Key: &ownerKey, Value: &goodVal})
	valid, missing = awstagging.VerifyTagsExist(tags)
	assert.False(t, valid)
	assert.Len(t, missing, 1)

	tags = append(tags, awstagging.TagItem{Key: &managedByKey, Value: &goodVal})
	valid, missing = awstagging.VerifyTagsExist(tags)
	assert.True(t, valid)
	assert.Len(t, missing, 0)

	// Now do format
	valid, badTags := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid)
	assert.Len(t, badTags, 0)

	tags[5].Value = &badVal
	valid, badTags = awstagging.VerifyTagsValueFormat(tags)
	assert.False(t, valid)
	assert.Len(t, badTags, 1)

	// name tag is element 3
	tags[3].Value = &goodNameTag
	valid, badTags = awstagging.VerifyTagsValueFormat(tags)
	assert.False(t, valid)
	assert.Len(t, badTags, 1)

	tags[3].Value = &badNameTag
	valid, badTags = awstagging.VerifyTagsValueFormat(tags)
	assert.False(t, valid)
	assert.Len(t, badTags, 2)
}

func TestVerifyTagsValueFormat(t *testing.T) {
	appKey := "application"
	compKey := "component"
	nameKey := "Name"
	goodVal := "UnitTest"
	goodNameTag := "Asfd-_ 2134"
	awsKey := "AmazonECSManaged"
	badVal := "true"

	var tags = []awstagging.TagItem{}
	tags = append(tags, awstagging.TagItem{Key: &appKey, Value: &goodVal})
	tags = append(tags, awstagging.TagItem{Key: &nameKey, Value: &goodNameTag})

	valid, badFormat := awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid)
	assert.Len(t, badFormat, 0)

	// Add a tag that we should be ignoring with "bad" value
	tags = append(tags, awstagging.TagItem{Key: &awsKey, Value: &badVal})
	valid, badFormat = awstagging.VerifyTagsValueFormat(tags)
	assert.True(t, valid)
	assert.Len(t, badFormat, 0)

	// now add one that has a bad format that we should be checking
	tags = append(tags, awstagging.TagItem{Key: &compKey, Value: &badVal})
	valid, badFormat = awstagging.VerifyTagsValueFormat(tags)
	assert.False(t, valid)
	assert.Len(t, badFormat, 1)
	assert.Equal(t, "Tag component has invalid value true", badFormat[0])

}