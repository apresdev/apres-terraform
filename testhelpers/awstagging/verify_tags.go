package awstagging

import "regexp"

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
	found_tags := make(map[string]bool)
	for _, expected := range ExpectedTags {
		found_tags[expected] = false
	}

	// Loop through the tags passed in, mark them as found.
	for _, tag := range tags {
		found_tags[*tag.Key] = true
	}

	var missing_tags []string
	for key, found := range found_tags {
		if !found {
	    	missing_tags = append(missing_tags, key)
	 	}
	}
	if len(missing_tags) > 0 {
		return false, missing_tags
	} else {
	    return true, []string{}
	}
}

func VerifyTagsValueFormat(tags []TagItem) (bool, []string) {
	bad_tags := make([]TagItem, 0)
	// Regex for all tag values except Name
	value_regex, _ := regexp.Compile("^[A-Z][a-zA-Z0-9]+$")
	// Regex for Name tags
	name_regex, _ := regexp.Compile("^[A-Z][a-zA-Z0-9-_ ]+$")
	for _, tag := range tags {
		if *tag.Key == "Name" {
			if !name_regex.MatchString(*tag.Value) {
				bad_tags = append(bad_tags, tag)
			}
		} else {
		 	if !value_regex.MatchString(*tag.Value) {
				bad_tags = append(bad_tags, tag)
			}
		}
	}
	if len(bad_tags) > 0 {
		var message []string
		for _, tag := range bad_tags {
			message = append(message, "Tag " + *tag.Key + " has invalid value " + *tag.Value)
		}
		return false, message
	} else {
		return true, []string{}
	}
}