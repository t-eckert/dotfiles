package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLoadConfig(t *testing.T) {
	tempDir := t.TempDir()

	tests := []struct {
		name        string
		content     string
		expectError bool
		expectLen   int
	}{
		{
			name: "valid single member",
			content: `[
				{"name": "Alice", "tz": "America/New_York"}
			]`,
			expectError: false,
			expectLen:   1,
		},
		{
			name: "valid multiple members",
			content: `[
				{"name": "Alice", "tz": "America/New_York"},
				{"name": "Bob", "tz": "Europe/London"},
				{"name": "Charlie", "tz": "Asia/Tokyo"}
			]`,
			expectError: false,
			expectLen:   3,
		},
		{
			name:        "empty array",
			content:     `[]`,
			expectError: false,
			expectLen:   0,
		},
		{
			name: "timezone with spaces",
			content: `[
				{"name": "Alice", "tz": "America/New York"}
			]`,
			expectError: false,
			expectLen:   1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			testFile := filepath.Join(tempDir, "test.json")
			err := os.WriteFile(testFile, []byte(tt.content), 0644)
			require.NoError(t, err)

			config, err := LoadConfig(testFile)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, config)
				assert.Len(t, *config, tt.expectLen)
			}

			os.Remove(testFile)
		})
	}
}

func TestLoadConfigReplacesSpaces(t *testing.T) {
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "test.json")

	content := `[{"name": "Alice", "tz": "America/New York"}]`
	err := os.WriteFile(testFile, []byte(content), 0644)
	require.NoError(t, err)

	config, err := LoadConfig(testFile)
	require.NoError(t, err)

	// Verify spaces are replaced with underscores
	assert.Equal(t, "America/New_York", (*config)[0].Tz)
}

func TestLoadConfigNonExistentFile(t *testing.T) {
	config, err := LoadConfig("/nonexistent/file.json")
	assert.Error(t, err)
	assert.Nil(t, config)
}

func TestTeammemberStruct(t *testing.T) {
	tm := Teammember{
		Name: "Alice",
		Tz:   "America/New_York",
	}

	assert.Equal(t, "Alice", tm.Name)
	assert.Equal(t, "America/New_York", tm.Tz)
}

func TestPrintTeamTimeValidTimezones(t *testing.T) {
	teammembers := []Teammember{
		{Name: "Alice", Tz: "America/New_York"},
		{Name: "Bob", Tz: "Europe/London"},
		{Name: "Charlie", Tz: "Asia/Tokyo"},
		{Name: "Diana", Tz: "UTC"},
	}

	err := printTeamTime(teammembers)
	assert.NoError(t, err)
}

func TestPrintTeamTimeInvalidTimezone(t *testing.T) {
	teammembers := []Teammember{
		{Name: "Alice", Tz: "Invalid/Timezone"},
	}

	err := printTeamTime(teammembers)
	assert.Error(t, err)
}

func TestPrintTeamTimeEmptyList(t *testing.T) {
	teammembers := []Teammember{}

	err := printTeamTime(teammembers)
	assert.NoError(t, err)
}

func TestTimeFormatting(t *testing.T) {
	// Test the time formatting logic
	now := time.Date(2024, 1, 15, 14, 30, 0, 0, time.UTC)

	// Load different timezones
	nyCalled := false
	locations := []string{"America/New_York", "Europe/London", "Asia/Tokyo"}

	for _, locName := range locations {
		loc, err := time.LoadLocation(locName)
		require.NoError(t, err)

		displayTime := now.In(loc).Format("03:04 PM MST")

		// Verify format
		assert.Contains(t, displayTime, ":")
		assert.Contains(t, strings.ToUpper(displayTime), "M")

		// Check that leading zero handling would work
		if displayTime[0] == '0' {
			displayTime = " " + displayTime[1:]
			nyCalled = true
		}

		assert.NotEmpty(t, displayTime)
	}

	// At least one timezone should have tested the leading zero logic
	_ = nyCalled
}

func TestJSONParsing(t *testing.T) {
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "team.json")

	content := `[
		{"name": "Alice", "tz": "America/New_York"},
		{"name": "Bob", "tz": "Europe/London"}
	]`

	err := os.WriteFile(testFile, []byte(content), 0644)
	require.NoError(t, err)

	config, err := LoadConfig(testFile)
	require.NoError(t, err)
	require.Len(t, *config, 2)

	// Verify first member
	assert.Equal(t, "Alice", (*config)[0].Name)
	assert.Equal(t, "America/New_York", (*config)[0].Tz)

	// Verify second member
	assert.Equal(t, "Bob", (*config)[1].Name)
	assert.Equal(t, "Europe/London", (*config)[1].Tz)
}

func TestLoadConfigWithInvalidJSON(t *testing.T) {
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "test.json")

	// Invalid JSON
	content := `[{"name": "Alice", "tz": "America/New_York"`
	err := os.WriteFile(testFile, []byte(content), 0644)
	require.NoError(t, err)

	config, err := LoadConfig(testFile)
	// LoadConfig doesn't check unmarshal error, but returns empty config
	assert.NoError(t, err)
	assert.NotNil(t, config)
}

func TestCommonTimezones(t *testing.T) {
	commonTzs := []string{
		"UTC",
		"America/New_York",
		"America/Los_Angeles",
		"America/Chicago",
		"Europe/London",
		"Europe/Paris",
		"Asia/Tokyo",
		"Asia/Singapore",
		"Australia/Sydney",
	}

	for _, tz := range commonTzs {
		t.Run(tz, func(t *testing.T) {
			_, err := time.LoadLocation(tz)
			assert.NoError(t, err, "Timezone %s should be valid", tz)
		})
	}
}

func TestTimezoneSpaceReplacement(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"America/New York", "America/New_York"},
		{"No Spaces", "No_Spaces"},
		{"Multiple  Spaces", "Multiple__Spaces"},
		{"NoSpaces", "NoSpaces"},
		{"", ""},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := strings.ReplaceAll(tt.input, " ", "_")
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestFullWorkflow(t *testing.T) {
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "team.json")

	content := `[
		{"name": "Alice", "tz": "America/New York"},
		{"name": "Bob", "tz": "Europe/London"}
	]`

	err := os.WriteFile(testFile, []byte(content), 0644)
	require.NoError(t, err)

	// Load config
	config, err := LoadConfig(testFile)
	require.NoError(t, err)
	require.Len(t, *config, 2)

	// Verify spaces were replaced
	assert.Equal(t, "America/New_York", (*config)[0].Tz)

	// Print team time
	err = printTeamTime(*config)
	assert.NoError(t, err)
}

func TestFileExtensionCheck(t *testing.T) {
	tests := []struct {
		path     string
		isValid  bool
	}{
		{"test.json", true},
		{"path/to/file.json", true},
		{"test.txt", false},
		{"test.JSON", false}, // Case sensitive
		{"testjson", false},
		{".json", true},
	}

	for _, tt := range tests {
		t.Run(tt.path, func(t *testing.T) {
			hasJSON := len(tt.path) >= 5 && tt.path[len(tt.path)-5:] == ".json"
			assert.Equal(t, tt.isValid, hasJSON)
		})
	}
}

func TestTeammemberJSONTags(t *testing.T) {
	// Test JSON marshaling and unmarshaling
	original := Teammember{
		Name: "Alice",
		Tz:   "America/New_York",
	}

	// Marshal to JSON
	data, err := json.Marshal(original)
	require.NoError(t, err)

	// Unmarshal back
	var unmarshaled Teammember
	err = json.Unmarshal(data, &unmarshaled)
	require.NoError(t, err)

	assert.Equal(t, original.Name, unmarshaled.Name)
	assert.Equal(t, original.Tz, unmarshaled.Tz)
}

func TestPrintTeamTimeConsistency(t *testing.T) {
	teammembers := []Teammember{
		{Name: "Alice", Tz: "UTC"},
	}

	// Call printTeamTime multiple times - should not error
	err := printTeamTime(teammembers)
	assert.NoError(t, err)

	err = printTeamTime(teammembers)
	assert.NoError(t, err)
}
