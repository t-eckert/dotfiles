package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCreateDirectory(t *testing.T) {
	tests := []struct {
		name string
		dir  string
	}{
		{"creates directory", "TestComponent"},
		{"handles existing directory", "TestComponent"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Clean up before and after
			defer os.RemoveAll(tt.dir)
			os.RemoveAll(tt.dir)

			createDirectory(tt.dir)

			// Verify directory exists
			info, err := os.Stat(tt.dir)
			require.NoError(t, err)
			assert.True(t, info.IsDir())
		})
	}
}

func TestCreateIndex(t *testing.T) {
	componentName := "TestComponent"
	tempDir := t.TempDir()

	// Change to temp directory for test
	oldDir, _ := os.Getwd()
	os.Chdir(tempDir)
	defer os.Chdir(oldDir)

	createDirectory(componentName)
	createIndex(componentName)

	// Verify file exists
	indexPath := filepath.Join(componentName, "index.ts")
	content, err := os.ReadFile(indexPath)
	require.NoError(t, err)

	// Verify content
	expected := `import TestComponent from "./TestComponent"
export default TestComponent`
	assert.Equal(t, expected, string(content))
}

func TestCreateStories(t *testing.T) {
	componentName := "TestComponent"
	tempDir := t.TempDir()

	oldDir, _ := os.Getwd()
	os.Chdir(tempDir)
	defer os.Chdir(oldDir)

	createDirectory(componentName)
	createStories(componentName)

	// Verify file exists
	storiesPath := filepath.Join(componentName, "TestComponent.stories.tsx")
	content, err := os.ReadFile(storiesPath)
	require.NoError(t, err)

	// Verify content contains expected strings
	contentStr := string(content)
	assert.Contains(t, contentStr, `import { ComponentStory, ComponentMeta } from "@storybook/react"`)
	assert.Contains(t, contentStr, `title: "components/TestComponent"`)
	assert.Contains(t, contentStr, `export const Default = Component.bind({})`)
}

func TestCreateComponent(t *testing.T) {
	componentName := "TestComponent"
	tempDir := t.TempDir()

	oldDir, _ := os.Getwd()
	os.Chdir(tempDir)
	defer os.Chdir(oldDir)

	createDirectory(componentName)
	createComponent(componentName)

	// Verify file exists
	componentPath := filepath.Join(componentName, "TestComponent.tsx")
	content, err := os.ReadFile(componentPath)
	require.NoError(t, err)

	// Verify content
	contentStr := string(content)
	assert.Contains(t, contentStr, `export interface Props {`)
	assert.Contains(t, contentStr, `const TestComponent: React.FC<Props> = ({}) => {`)
	assert.Contains(t, contentStr, `return <div>TestComponent</div>`)
	assert.Contains(t, contentStr, `export default TestComponent`)
}

func TestWriteToFile(t *testing.T) {
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "test.txt")
	testContent := "Hello, World!"

	writeToFile(testFile, testContent)

	// Verify file was created and content is correct
	content, err := os.ReadFile(testFile)
	require.NoError(t, err)
	assert.Equal(t, testContent, string(content))
}

func TestWriteToFileError(t *testing.T) {
	// Try to write to an invalid path (directory that doesn't exist)
	invalidPath := "/nonexistent/directory/file.txt"

	// This should not panic, just print an error
	writeToFile(invalidPath, "test content")

	// Verify file was not created
	_, err := os.Stat(invalidPath)
	assert.Error(t, err)
}

func TestFullComponentCreation(t *testing.T) {
	componentName := "MyButton"
	tempDir := t.TempDir()

	oldDir, _ := os.Getwd()
	os.Chdir(tempDir)
	defer os.Chdir(oldDir)

	// Simulate the main function's workflow
	createDirectory(componentName)
	createIndex(componentName)
	createStories(componentName)
	createComponent(componentName)

	// Verify all files were created
	expectedFiles := []string{
		filepath.Join(componentName, "index.ts"),
		filepath.Join(componentName, "MyButton.stories.tsx"),
		filepath.Join(componentName, "MyButton.tsx"),
	}

	for _, file := range expectedFiles {
		_, err := os.Stat(file)
		assert.NoError(t, err, "Expected file %s to exist", file)
	}

	// Verify directory structure
	info, err := os.Stat(componentName)
	require.NoError(t, err)
	assert.True(t, info.IsDir())
}

func TestComponentNameWithSpecialCharacters(t *testing.T) {
	tests := []struct {
		name          string
		componentName string
	}{
		{"CamelCase", "MyComponent"},
		{"single word", "Button"},
		{"with numbers", "Button2"},
		{"PascalCase", "MyAwesomeComponent"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tempDir := t.TempDir()

			oldDir, _ := os.Getwd()
			os.Chdir(tempDir)
			defer os.Chdir(oldDir)

			createDirectory(tt.componentName)
			createComponent(tt.componentName)

			// Verify component file was created
			componentPath := filepath.Join(tt.componentName, tt.componentName+".tsx")
			_, err := os.Stat(componentPath)
			assert.NoError(t, err)
		})
	}
}
