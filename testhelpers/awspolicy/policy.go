package awspolicy

import (
	"encoding/json"
	"fmt"
)

type Policy struct {
	Version   string
	Statement []Statement
}

type Statement struct {
	Sid       string
	Effect    string
	Principal []map[string]string
	Action    []string
	Resource  []string
}

func (s *Statement) UnmarshalJSON(data []byte) (err error) {
	var temp map[string]interface{}
	if err := json.Unmarshal(data, &temp); err != nil {
		return nil
	}

	if sid, exists := temp["Sid"]; exists {
		var ok bool
		if s.Sid, ok = sid.(string); !ok {
			return fmt.Errorf("sid must be a string")
		}
	}

	if effect, exists := temp["Effect"]; exists {
		var ok bool
		if s.Effect, ok = effect.(string); !ok {
			return fmt.Errorf("effect must be a string")
		}
	}

	if principal, exists := temp["Principal"]; exists {

		switch v := principal.(type) {
		case map[string]interface{}:
			if s.Principal, err = wrapMapArray(v, stringMap); err != nil {
				return err
			}
		case []map[string]interface{}:
			if s.Principal, err = mapArray(v, stringMap); err != nil {
				return err
			}
		default:
			return fmt.Errorf("principal must be either a map or array of maps")
		}
	}

	if action, exists := temp["Action"]; exists {

		switch v := action.(type) {
		case string:
			s.Action = wrapArray(v)
		case []interface{}:
			if s.Action, err = stringArray(v); err != nil {
				return err
			}
		default:
			return fmt.Errorf("action must be either a string or array of string")
		}
	}

	if resource, exists := temp["Resource"]; exists {

		switch v := resource.(type) {
		case string:
			s.Resource = wrapArray(v)
		case []interface{}:
			if s.Resource, err = stringArray(v); err != nil {
				return err
			}
		default:
			return fmt.Errorf("resource must be either a string or array of string")
		}
	}

	return nil
}

func stringMap(input map[string]interface{}) (map[string]string, error) {
	return mapMap(input, identity, toString)
}

func stringArray(items []interface{}) ([]string, error) {
	return mapArray(items, toString)
}

type TransformFn[I any, O any] func(input I) (O, error)

func mapMap[IK comparable, IV any, OK comparable, OV any](input map[IK]IV, keyTransformFn TransformFn[IK, OK], valueTransformFn TransformFn[IV, OV]) (result map[OK]OV, err error) {
	result = make(map[OK]OV)

	for ik, iv := range input {

		var ok OK
		var ov OV

		if ok, err = keyTransformFn(ik); err != nil {
			return nil, err
		}
		if ov, err = valueTransformFn(iv); err != nil {
			return nil, err
		}

		result[ok] = ov

	}

	return result, nil
}

func mapArray[I any, O any](input []I, transformFn TransformFn[I, O]) (result []O, err error) {

	result = make([]O, len(input))

	for i, v := range input {
		if result[i], err = transformFn(v); err != nil {
			return nil, err
		}
	}

	return result, nil
}

func toString(input interface{}) (string, error) {
	if v, ok := input.(string); ok {
		return v, nil
	}

	return "", fmt.Errorf("encountered non string %v", input)
}

func identity[I any](input I) (I, error) {
	return input, nil
}

func wrapMapArray[I any, O any](item I, transformFn TransformFn[I, O]) (result []O, err error) {
	v, err := transformFn(item)
	if err != nil {
		return nil, err
	}

	return wrapArray(v), nil

}

func wrapArray[T any](item T) []T {
	return []T{item}

}
