package s3utils

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

// S3EmptyBucket will completely empty an S3 bucket of all objects, object versions, and delete markers.
//
// There is no way in the AWS SDK v2 to empty a bucket in a single call, so we're borrowing this code from
// https://www.codershaven.com/posts/empty-s3-bucket-and-dynamodb-table-using-the-aws-sdk/
//
func S3EmptyBucket(s3Client *s3.Client, bucketName string) error {
	// iterate over all objects and delete them
	listObjectsInput := &s3.ListObjectsV2Input{
		Bucket: aws.String(bucketName),
	}
	for {
		listObjectsOutput, err := s3Client.ListObjectsV2(context.Background(), listObjectsInput)
		if err != nil {
			return fmt.Errorf("unable to list bucket objects: %w", err)
		}

		objects := []types.ObjectIdentifier{}
		for _, item := range listObjectsOutput.Contents {
			objects = append(objects, types.ObjectIdentifier{
				Key: item.Key,
			})
		}
		err = S3DeleteObjects(s3Client, bucketName, objects)
		if err != nil {
			return err
		}

		if *listObjectsOutput.IsTruncated {
			listObjectsInput.ContinuationToken = listObjectsOutput.ContinuationToken
		} else {
			break
		}
	}

	// iterate over all object versions and delete them
	listVersionsInput := &s3.ListObjectVersionsInput{
		Bucket: aws.String(bucketName),
	}
	for {
		listVersionsOutput, err := s3Client.ListObjectVersions(context.Background(), listVersionsInput)
		if err != nil {
			return fmt.Errorf("unable to list object versions: %w", err)
		}

		deleteMarkers := []types.ObjectIdentifier{}
		for _, item := range listVersionsOutput.DeleteMarkers {
			deleteMarkers = append(deleteMarkers, types.ObjectIdentifier{
				Key:       item.Key,
				VersionId: item.VersionId,
			})
		}
		err = S3DeleteObjects(s3Client, bucketName, deleteMarkers)
		if err != nil {
			return err
		}

		versions := []types.ObjectIdentifier{}
		for _, item := range listVersionsOutput.Versions {
			versions = append(versions, types.ObjectIdentifier{
				Key:       item.Key,
				VersionId: item.VersionId,
			})
		}
		err = S3DeleteObjects(s3Client, bucketName, versions)
		if err != nil {
			return err
		}

		if *listVersionsOutput.IsTruncated {
			listVersionsInput.VersionIdMarker = listVersionsOutput.NextVersionIdMarker
			listVersionsInput.KeyMarker = listVersionsOutput.NextKeyMarker
		} else {
			break
		}
	}

	return nil
}

// S3DeleteObjects will delete all S3 objects provided, breaking them into chunks of 1000 per request.
func S3DeleteObjects(s3Client *s3.Client, bucketName string, objects []types.ObjectIdentifier) error {
	// s3 DeleteObjects supports batch deleting up to 1000 objects at a time
	return ProcessChunks(objects, 1000, func(toDelete []types.ObjectIdentifier) error {
		out, err := s3Client.DeleteObjects(context.Background(), &s3.DeleteObjectsInput{
			Bucket: aws.String(bucketName),
			Delete: &types.Delete{
				Quiet:   aws.Bool(true), // in quiet mode the response includes only keys where the delete action encountered an error
				Objects: toDelete,
			},
		})
		if err != nil {
			return fmt.Errorf("failed to batch delete objects: %w", err)
		}
		if len(out.Errors) > 0 {
			return fmt.Errorf("at least one object failed to delete: %v - %v", out.Errors[0].Code, out.Errors[0].Message)
		}
		return nil
	})
}

// ProcessChunks will break a slice into chunks of the given size and process each chunk sequentially.
func ProcessChunks[T any](s []T, chunkSize int, process func([]T) error) error {
	for i := 0; i < len(s); i += chunkSize {
		upper := i + chunkSize
		if upper > len(s) {
			upper = len(s)
		}
		chunk := s[i:upper]

		err := process(chunk)
		if err != nil {
			return err
		}
	}
	return nil
}
