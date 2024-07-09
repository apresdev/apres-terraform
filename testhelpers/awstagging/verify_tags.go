package awstagging

import (
	"regexp"

	"golang.org/x/exp/slices"
)

// Unfortunately each AWS service in the go SDK has its own Tag struct, so we need to define our own
// and users of this library will need to convert the tags from the SDK to this struct.
type TagItem struct {
	Key *string
	Value *string
}

var ExpectedTags = []string {
	"application",
	"component",
	"environment",
	"Name",
	"owner",
	"managed-by",
}

func VerifyTagsExist(tags []TagItem) (bool, []string) {
	foundTags := make(map[string]bool)
	for _, expected := range ExpectedTags {
		foundTags[expected] = false
	}

	// Loop through the tags passed in, mark them as found.
	for _, tag := range tags {
		foundTags[*tag.Key] = true
	}

	var missingTags []string
	for key, found := range foundTags {
		if !found {
	    	missingTags = append(missingTags, key)
	 	}
	}
	if len(missingTags) > 0 {
		return false, missingTags
	} else {
	    return true, []string{}
	}
}

// Verify Tags Value Format for the Apres tags, ignore the rest
func VerifyTagsValueFormat(tags []TagItem) (bool, []string) {
	badTags := make([]TagItem, 0)
	// Regex for all tag values except Name
	valueRegex, _ := regexp.Compile("^[A-Z][a-zA-Z0-9]+$")
	// Regex for Name tags
	nameRegex, _ := regexp.Compile("^[a-zA-Z0-9-_ ]+$")
	for _, tag := range tags {
		// Ignore tags not in the expected list, we only care about Apres tags
		// Some of the AWS tags will not follow the Apres format
		if (! slices.Contains(ExpectedTags, *tag.Key)) {
			continue
		}
		if *tag.Key == "Name" {
			if !nameRegex.MatchString(*tag.Value) {
				badTags = append(badTags, tag)
			}
		} else {
		 	if !valueRegex.MatchString(*tag.Value) {
				badTags = append(badTags, tag)
			}
		}
	}
	if len(badTags) > 0 {
		var message []string
		for _, tag := range badTags {
			message = append(message, "Tag " + *tag.Key + " has invalid value " + *tag.Value)
		}
		return false, message
	} else {
		return true, []string{}
	}
}