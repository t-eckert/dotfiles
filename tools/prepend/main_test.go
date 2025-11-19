package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestFetchAllFiles(t *testing.T) {
	tempDir := t.TempDir()

	// Create test files
	testFiles := []string{"file1.txt", "file2.txt", "test.log"}
	for _, file := range testFiles {
		_, err := os.Create(filepath.Join(tempDir, file))
		require.NoError(t, err)
	}

	tests := []struct {
		name     string
		globs    []string
		expected int
	}{
		{
			name:     "single glob matches all txt files",
			globs:    []string{filepath.Join(tempDir, "*.txt")},
			expected: 2,
		},
		{
			name:     "single glob matches log file",
			globs:    []string{filepath.Join(tempDir, "*.log")},
			expected: 1,
		},
		{
			name:     "multiple globs",
			globs:    []string{filepath.Join(tempDir, "*.txt"), filepath.Join(tempDir, "*.log")},
			expected: 3,
		},
		{
			name:     "specific file",
			globs:    []string{filepath.Join(tempDir, "file1.txt")},
			expected: 1,
		},
		{
			name:     "no matches",
			globs:    []string{filepath.Join(tempDir, "*.nonexistent")},
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			files, err := fetchAllFiles(tt.globs)
			require.NoError(t, err)
			assert.Len(t, files, tt.expected)
		})
	}
}

func TestFetchAllFilesInvalidGlob(t *testing.T) {
	// Test with an invalid glob pattern
	invalidGlobs := []string{"[invalid"}
	files, err := fetchAllFiles(invalidGlobs)
	assert.Error(t, err)
	assert.Nil(t, files)
}

func TestPrependString(t *testing.T) {
	tests := []struct {
		name     string
		files    []string
		prepend  string
		expected [][2]string
	}{
		{
			name:    "prepend to single file",
			files:   []string{"file.txt"},
			prepend: "prefix_",
			expected: [][2]string{
				{"file.txt", "prefix_file.txt"},
			},
		},
		{
			name:    "prepend to multiple files",
			files:   []string{"file1.txt", "file2.txt"},
			prepend: "new_",
			expected: [][2]string{
				{"file1.txt", "new_file1.txt"},
				{"file2.txt", "new_file2.txt"},
			},
		},
		{
			name:    "empty prepend string",
			files:   []string{"file.txt"},
			prepend: "",
			expected: [][2]string{
				{"file.txt", "file.txt"},
			},
		},
		{
			name:    "prepend with special characters",
			files:   []string{"file.txt"},
			prepend: "123-",
			expected: [][2]string{
				{"file.txt", "123-file.txt"},
			},
		},
		{
			name:     "empty file list",
			files:    []string{},
			prepend:  "prefix_",
			expected: nil,
		},
		{
			name:    "files with paths",
			files:   []string{"/path/to/file.txt"},
			prepend: "prefix_",
			expected: [][2]string{
				{"/path/to/file.txt", "prefix_/path/to/file.txt"},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := prependString(tt.files, tt.prepend)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestRenameFiles(t *testing.T) {
	tempDir := t.TempDir()

	tests := []struct {
		name        string
		setup       func() [][2]string
		expectError bool
	}{
		{
			name: "rename single file",
			setup: func() [][2]string {
				file := filepath.Join(tempDir, "original.txt")
				_, err := os.Create(file)
				require.NoError(t, err)
				return [][2]string{
					{file, filepath.Join(tempDir, "renamed.txt")},
				}
			},
			expectError: false,
		},
		{
			name: "rename multiple files",
			setup: func() [][2]string {
				files := []string{"file1.txt", "file2.txt"}
				renames := [][2]string{}
				for i, f := range files {
					file := filepath.Join(tempDir, f)
					_, err := os.Create(file)
					require.NoError(t, err)
					newName := filepath.Join(tempDir, files[i][:len(files[i])-4]+"_renamed.txt")
					renames = append(renames, [2]string{file, newName})
				}
				return renames
			},
			expectError: false,
		},
		{
			name: "error on non-existent file",
			setup: func() [][2]string {
				return [][2]string{
					{filepath.Join(tempDir, "nonexistent.txt"), filepath.Join(tempDir, "renamed.txt")},
				}
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fileRenames := tt.setup()
			err := renameFiles(fileRenames)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)

				// Verify files were renamed
				for _, rename := range fileRenames {
					_, err := os.Stat(rename[1])
					assert.NoError(t, err, "Renamed file should exist")

					_, err = os.Stat(rename[0])
					assert.True(t, os.IsNotExist(err), "Original file should not exist")
				}
			}
		})
	}
}

func TestRenameFilesEmpty(t *testing.T) {
	err := renameFiles([][2]string{})
	assert.NoError(t, err, "Renaming empty list should not error")
}

func TestEndToEndPrependWorkflow(t *testing.T) {
	tempDir := t.TempDir()

	// Create test files directly in temp dir
	testFiles := []string{"file1.txt", "file2.txt", "document.log"}
	for _, file := range testFiles {
		_, err := os.Create(filepath.Join(tempDir, file))
		require.NoError(t, err)
	}

	// Change to temp directory to work with relative paths
	oldDir, _ := os.Getwd()
	err := os.Chdir(tempDir)
	require.NoError(t, err)
	defer os.Chdir(oldDir)

	// Fetch files using relative paths
	globs := []string{"*.txt"}
	files, err := fetchAllFiles(globs)
	require.NoError(t, err)
	assert.Len(t, files, 2)

	// Prepend string
	prepend := "backup_"
	fileRenames := prependString(files, prepend)
	assert.Len(t, fileRenames, 2)

	// Rename files
	err = renameFiles(fileRenames)
	require.NoError(t, err)

	// Verify renamed files exist
	expectedFiles := []string{"backup_file1.txt", "backup_file2.txt"}
	for _, file := range expectedFiles {
		_, err := os.Stat(file)
		assert.NoError(t, err, "File %s should exist", file)
	}

	// Verify original files don't exist
	for _, file := range testFiles[:2] {
		_, err := os.Stat(file)
		assert.True(t, os.IsNotExist(err), "Original file %s should not exist", file)
	}

	// Verify .log file still exists (wasn't matched by glob)
	_, err = os.Stat("document.log")
	assert.NoError(t, err, "Log file should still exist")
}

func TestPrependWithDirectoryStructure(t *testing.T) {
	tempDir := t.TempDir()
	subDir := filepath.Join(tempDir, "subdir")
	err := os.Mkdir(subDir, 0755)
	require.NoError(t, err)

	// Change to subdirectory (tool is designed to work in current dir)
	oldDir, _ := os.Getwd()
	err = os.Chdir(subDir)
	require.NoError(t, err)
	defer os.Chdir(oldDir)

	// Create files
	testFile := "file.txt"
	_, err = os.Create(testFile)
	require.NoError(t, err)

	// Fetch files
	globs := []string{"*.txt"}
	files, err := fetchAllFiles(globs)
	require.NoError(t, err)
	assert.Len(t, files, 1)

	// Prepend and rename
	fileRenames := prependString(files, "new_")
	err = renameFiles(fileRenames)
	require.NoError(t, err)

	// Verify
	expectedPath := "new_file.txt"
	_, err = os.Stat(expectedPath)
	assert.NoError(t, err)
}

func TestPrependPreservesFileContent(t *testing.T) {
	tempDir := t.TempDir()
	originalFile := filepath.Join(tempDir, "original.txt")
	content := []byte("Hello, World!\nThis is test content.")

	err := os.WriteFile(originalFile, content, 0644)
	require.NoError(t, err)

	// Rename file
	renames := [][2]string{
		{originalFile, filepath.Join(tempDir, "prefix_original.txt")},
	}
	err = renameFiles(renames)
	require.NoError(t, err)

	// Read renamed file
	renamedFile := filepath.Join(tempDir, "prefix_original.txt")
	newContent, err := os.ReadFile(renamedFile)
	require.NoError(t, err)

	assert.Equal(t, content, newContent, "File content should be preserved")
}
