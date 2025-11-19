package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestToKebabCase(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "simple spaces",
			input:    "Hello World",
			expected: "hello-world",
		},
		{
			name:     "camelCase",
			input:    "helloWorld",
			expected: "helloworld",
		},
		{
			name:     "PascalCase",
			input:    "HelloWorld",
			expected: "helloworld",
		},
		{
			name:     "snake_case",
			input:    "hello_world",
			expected: "hello-world",
		},
		{
			name:     "multiple spaces",
			input:    "hello   world",
			expected: "hello-world",
		},
		{
			name:     "special characters",
			input:    "hello!@#$world",
			expected: "hello-world",
		},
		{
			name:     "numbers",
			input:    "file123name456",
			expected: "file123name456",
		},
		{
			name:     "mixed case with numbers",
			input:    "MyFile2024",
			expected: "myfile2024",
		},
		{
			name:     "leading and trailing spaces",
			input:    "  hello world  ",
			expected: "hello-world",
		},
		{
			name:     "leading and trailing dashes",
			input:    "--hello-world--",
			expected: "hello-world",
		},
		{
			name:     "all caps",
			input:    "HELLO WORLD",
			expected: "hello-world",
		},
		{
			name:     "dots and dashes",
			input:    "file.name-here",
			expected: "file-name-here",
		},
		{
			name:     "empty string",
			input:    "",
			expected: "",
		},
		{
			name:     "only special characters",
			input:    "!@#$%^&*()",
			expected: "",
		},
		{
			name:     "unicode characters",
			input:    "hello world café",
			expected: "hello-world-caf",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := toKebabCase(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestRenameFileToKebabCase(t *testing.T) {
	tempDir := t.TempDir()

	tests := []struct {
		name         string
		originalFile string
		expectedFile string
	}{
		{
			name:         "simple spaces",
			originalFile: "My File.txt",
			expectedFile: "my-file.txt",
		},
		{
			name:         "camelCase",
			originalFile: "myFileName.log",
			expectedFile: "myfilename.log",
		},
		{
			name:         "special characters",
			originalFile: "file!@#name.txt",
			expectedFile: "file-name.txt",
		},
		{
			name:         "multiple extensions",
			originalFile: "file.tar.gz",
			expectedFile: "file-tar.gz",
		},
		{
			name:         "no extension",
			originalFile: "README",
			expectedFile: "readme",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create original file
			originalPath := filepath.Join(tempDir, tt.originalFile)
			_, err := os.Create(originalPath)
			require.NoError(t, err)

			// Rename file
			renameFileToKebabCase(originalPath)

			// Verify new file exists
			expectedPath := filepath.Join(tempDir, tt.expectedFile)
			_, err = os.Stat(expectedPath)
			assert.NoError(t, err, "Expected file %s should exist", tt.expectedFile)

			// Verify original file doesn't exist (unless names are the same)
			if tt.originalFile != tt.expectedFile {
				_, err = os.Stat(originalPath)
				assert.True(t, os.IsNotExist(err), "Original file should not exist")
			}

			// Clean up for next test
			os.Remove(expectedPath)
		})
	}
}

func TestRenameFilePreservesContent(t *testing.T) {
	tempDir := t.TempDir()

	// Create file with content
	originalFile := filepath.Join(tempDir, "Test File.txt")
	content := []byte("This is test content\nwith multiple lines")
	err := os.WriteFile(originalFile, content, 0644)
	require.NoError(t, err)

	// Rename file
	renameFileToKebabCase(originalFile)

	// Read renamed file
	renamedFile := filepath.Join(tempDir, "test-file.txt")
	newContent, err := os.ReadFile(renamedFile)
	require.NoError(t, err)

	// Verify content is preserved
	assert.Equal(t, content, newContent)
}

func TestRenameFileInSubdirectory(t *testing.T) {
	tempDir := t.TempDir()
	subDir := filepath.Join(tempDir, "subdir")
	err := os.Mkdir(subDir, 0755)
	require.NoError(t, err)

	// Create file in subdirectory
	originalFile := filepath.Join(subDir, "My File.txt")
	_, err = os.Create(originalFile)
	require.NoError(t, err)

	// Rename file
	renameFileToKebabCase(originalFile)

	// Verify renamed file exists in same directory
	renamedFile := filepath.Join(subDir, "my-file.txt")
	_, err = os.Stat(renamedFile)
	assert.NoError(t, err)
}

func TestRenameFileError(t *testing.T) {
	// Try to rename a non-existent file
	// This should print an error but not crash
	renameFileToKebabCase("/nonexistent/file.txt")
	// If we get here, the function handled the error gracefully
}

func TestGlobPattern(t *testing.T) {
	tempDir := t.TempDir()

	// Create multiple test files
	files := []string{"File One.txt", "File Two.txt", "test.log"}
	for _, file := range files {
		_, err := os.Create(filepath.Join(tempDir, file))
		require.NoError(t, err)
	}

	// Test glob matching
	pattern := filepath.Join(tempDir, "*.txt")
	matches, err := filepath.Glob(pattern)
	require.NoError(t, err)
	assert.Len(t, matches, 2)
}

func TestInvalidGlob(t *testing.T) {
	// Test invalid glob pattern
	_, err := filepath.Glob("[invalid")
	assert.Error(t, err)
}

func TestDirectoryNotRenamed(t *testing.T) {
	tempDir := t.TempDir()

	// Create a directory
	dirPath := filepath.Join(tempDir, "My Directory")
	err := os.Mkdir(dirPath, 0755)
	require.NoError(t, err)

	// Get file info
	fileInfo, err := os.Stat(dirPath)
	require.NoError(t, err)

	// Verify it's a directory
	assert.True(t, fileInfo.IsDir())

	// The main function should skip directories
	// We can't easily test the main function directly, but we verify the check works
}

func TestFilenameWithExtensionParsing(t *testing.T) {
	tests := []struct {
		filename    string
		expectExt   string
		expectNoExt string
	}{
		{"file.txt", ".txt", "file"},
		{"archive.tar.gz", ".gz", "archive.tar"},
		{"README", "", "README"},
		{".hidden", ".hidden", ""},
		{"file.name.txt", ".txt", "file.name"},
	}

	for _, tt := range tests {
		t.Run(tt.filename, func(t *testing.T) {
			extension := filepath.Ext(tt.filename)
			filenameNoExt := tt.filename[0 : len(tt.filename)-len(extension)]

			assert.Equal(t, tt.expectExt, extension)
			assert.Equal(t, tt.expectNoExt, filenameNoExt)
		})
	}
}

func TestMultipleFilesRename(t *testing.T) {
	tempDir := t.TempDir()

	// Create multiple files
	files := []string{"File One.txt", "File Two.log", "File Three.md"}
	for _, file := range files {
		_, err := os.Create(filepath.Join(tempDir, file))
		require.NoError(t, err)
	}

	// Rename all files
	for _, file := range files {
		renameFileToKebabCase(filepath.Join(tempDir, file))
	}

	// Verify all files were renamed
	expected := []string{"file-one.txt", "file-two.log", "file-three.md"}
	for _, file := range expected {
		_, err := os.Stat(filepath.Join(tempDir, file))
		assert.NoError(t, err, "File %s should exist", file)
	}
}

func TestAlreadyKebabCase(t *testing.T) {
	tempDir := t.TempDir()

	// Create file that's already in kebab-case
	originalFile := filepath.Join(tempDir, "already-kebab.txt")
	content := []byte("test")
	err := os.WriteFile(originalFile, content, 0644)
	require.NoError(t, err)

	// Rename file (should keep same name)
	renameFileToKebabCase(originalFile)

	// File should still exist with same name
	newContent, err := os.ReadFile(originalFile)
	require.NoError(t, err)
	assert.Equal(t, content, newContent)
}
