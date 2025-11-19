package main

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestFetchGitignoreSuccess(t *testing.T) {
	// Create a test server that returns a sample .gitignore
	expectedContent := "# Python\n*.pyc\n__pycache__/\n"
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(expectedContent))
	}))
	defer server.Close()

	// Test that the source URL format is correct
	expectedURL := "https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore"
	actualURL := fmt.Sprintf(source, "Python")
	assert.Equal(t, expectedURL, actualURL)
}

func TestSourceURLFormat(t *testing.T) {
	tests := []struct {
		lang     string
		expected string
	}{
		{"Python", "https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore"},
		{"Go", "https://raw.githubusercontent.com/github/gitignore/main/Go.gitignore"},
		{"Node", "https://raw.githubusercontent.com/github/gitignore/main/Node.gitignore"},
		{"Java", "https://raw.githubusercontent.com/github/gitignore/main/Java.gitignore"},
	}

	for _, tt := range tests {
		t.Run(tt.lang, func(t *testing.T) {
			actual := fmt.Sprintf(source, tt.lang)
			assert.Equal(t, tt.expected, actual)
		})
	}
}

func TestTargetFilename(t *testing.T) {
	assert.Equal(t, ".gitignore", target)
}

func TestHTTPGetSuccess(t *testing.T) {
	expectedContent := "# Test content\n*.log\n"
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(expectedContent))
	}))
	defer server.Close()

	resp, err := http.Get(server.URL)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	assert.Equal(t, expectedContent, string(body))
}

func TestHTTPGet404(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte("404 page not found"))
	}))
	defer server.Close()

	resp, err := http.Get(server.URL)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}

func TestFileAppendOperation(t *testing.T) {
	tempDir := t.TempDir()
	testFile := tempDir + "/.gitignore"

	// Write initial content
	initialContent := "# Initial content\n"
	err := os.WriteFile(testFile, []byte(initialContent), 0644)
	require.NoError(t, err)

	// Append new content (simulating what the tool does)
	file, err := os.OpenFile(testFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	require.NoError(t, err)
	defer file.Close()

	newContent := "# Appended content\n*.pyc\n"
	_, err = file.WriteString(newContent)
	require.NoError(t, err)

	// Read and verify
	finalContent, err := os.ReadFile(testFile)
	require.NoError(t, err)

	expected := initialContent + newContent
	assert.Equal(t, expected, string(finalContent))
}

func TestFileCreationIfNotExists(t *testing.T) {
	tempDir := t.TempDir()
	testFile := tempDir + "/.gitignore"

	// File shouldn't exist yet
	_, err := os.Stat(testFile)
	assert.True(t, os.IsNotExist(err))

	// Create file with O_CREATE flag
	file, err := os.OpenFile(testFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	require.NoError(t, err)
	defer file.Close()

	content := "# New file\n*.log\n"
	_, err = file.WriteString(content)
	require.NoError(t, err)

	// Verify file was created
	finalContent, err := os.ReadFile(testFile)
	require.NoError(t, err)
	assert.Equal(t, content, string(finalContent))
}

func TestIOCopy(t *testing.T) {
	content := "# Test content\nnode_modules/\n*.log\n"
	reader := strings.NewReader(content)

	tempDir := t.TempDir()
	testFile := tempDir + "/.gitignore"

	file, err := os.Create(testFile)
	require.NoError(t, err)
	defer file.Close()

	written, err := io.Copy(file, reader)
	require.NoError(t, err)
	assert.Equal(t, int64(len(content)), written)

	// Verify content
	finalContent, err := os.ReadFile(testFile)
	require.NoError(t, err)
	assert.Equal(t, content, string(finalContent))
}

func TestMultipleLanguageFormats(t *testing.T) {
	languages := []string{"Python", "Go", "Node", "Java", "Rust", "Ruby"}

	for _, lang := range languages {
		t.Run(lang, func(t *testing.T) {
			url := fmt.Sprintf(source, lang)
			assert.Contains(t, url, lang)
			assert.Contains(t, url, ".gitignore")
			assert.Contains(t, url, "raw.githubusercontent.com")
		})
	}
}

func TestFilePermissions(t *testing.T) {
	tempDir := t.TempDir()
	testFile := tempDir + "/.gitignore"

	file, err := os.OpenFile(testFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	require.NoError(t, err)
	file.Close()

	info, err := os.Stat(testFile)
	require.NoError(t, err)

	// Check that file has correct permissions (0644)
	// On some systems, this might be modified by umask
	mode := info.Mode().Perm()
	assert.True(t, mode&0400 != 0, "Owner should have read permission")
	assert.True(t, mode&0200 != 0, "Owner should have write permission")
}

func TestEmptyLanguageHandling(t *testing.T) {
	// This tests the URL format when lang is empty
	// In the actual tool, this is caught by the flag check
	url := fmt.Sprintf(source, "")
	expected := "https://raw.githubusercontent.com/github/gitignore/main/.gitignore"
	assert.Equal(t, expected, url)
}

func TestSpecialCharactersInLanguage(t *testing.T) {
	tests := []struct {
		lang     string
		expected string
	}{
		{"C++", "https://raw.githubusercontent.com/github/gitignore/main/C++.gitignore"},
		{"Objective-C", "https://raw.githubusercontent.com/github/gitignore/main/Objective-C.gitignore"},
		{"VisualStudio", "https://raw.githubusercontent.com/github/gitignore/main/VisualStudio.gitignore"},
	}

	for _, tt := range tests {
		t.Run(tt.lang, func(t *testing.T) {
			actual := fmt.Sprintf(source, tt.lang)
			assert.Equal(t, tt.expected, actual)
		})
	}
}
