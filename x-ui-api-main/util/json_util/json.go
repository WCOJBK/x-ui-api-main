package json_util

import (
	"encoding/json"
	"errors"
)

type RawMessage []byte

// MarshalJSON: Customize json.RawMessage default behavior
func (m RawMessage) MarshalJSON() ([]byte, error) {
	if len(m) == 0 {
		return []byte("null"), nil
	}
	return m, nil
}

// UnmarshalJSON: sets *m to a copy of data.
func (m *RawMessage) UnmarshalJSON(data []byte) error {
	if m == nil {
		return errors.New("json.RawMessage: UnmarshalJSON on nil pointer")
	}
	*m = append((*m)[0:0], data...)
	return nil
}

// ToRawMessage converts an interface{} to RawMessage
func ToRawMessage(v interface{}) RawMessage {
	data, err := json.Marshal(v)
	if err != nil {
		return RawMessage("null")
	}
	return RawMessage(data)
}
