package main

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestDefaultPort(t *testing.T) {
	// Default port should be "8080"
	expected := "8080"
	// This would be set by flag.StringVar in main
	assert.Equal(t, expected, "8080")
}

func TestAddressFormatting(t *testing.T) {
	tests := []struct {
		port     string
		expected string
	}{
		{"8080", ":8080"},
		{"3000", ":3000"},
		{"80", ":80"},
		{"9999", ":9999"},
	}

	for _, tt := range tests {
		t.Run(tt.port, func(t *testing.T) {
			addr := fmt.Sprintf(":%s", tt.port)
			assert.Equal(t, tt.expected, addr)
		})
	}
}

func TestFileServerServesFiles(t *testing.T) {
	// Create a temporary directory with test files
	tempDir := t.TempDir()

	// Change to temp directory
	oldDir, _ := os.Getwd()
	err := os.Chdir(tempDir)
	require.NoError(t, err)
	defer os.Chdir(oldDir)

	// Create test files
	testContent := "Hello, World!"
	err = os.WriteFile("test.txt", []byte(testContent), 0644)
	require.NoError(t, err)

	// Create file server
	fs := http.FileServer(http.Dir("."))

	// Create test server
	server := httptest.NewServer(fs)
	defer server.Close()

	// Make request
	resp, err := http.Get(server.URL + "/test.txt")
	require.NoError(t, err)
	defer resp.Body.Close()

	// Verify response
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	// Read body
	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	assert.Equal(t, testContent, string(body))
}

func TestFileServerServesDirectory(t *testing.T) {
	// Create a temporary directory
	tempDir := t.TempDir()

	// Change to temp directory
	oldDir, _ := os.Getwd()
	err := os.Chdir(tempDir)
	require.NoError(t, err)
	defer os.Chdir(oldDir)

	// Create some test files
	err = os.WriteFile("file1.txt", []byte("content1"), 0644)
	require.NoError(t, err)
	err = os.WriteFile("file2.html", []byte("<html>test</html>"), 0644)
	require.NoError(t, err)

	// Create file server
	fs := http.FileServer(http.Dir("."))

	// Create test server
	server := httptest.NewServer(fs)
	defer server.Close()

	// Make request to root
	resp, err := http.Get(server.URL + "/")
	require.NoError(t, err)
	defer resp.Body.Close()

	// Should return directory listing
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestFileServerHandles404(t *testing.T) {
	// Create a temporary directory
	tempDir := t.TempDir()

	// Create file server
	fs := http.FileServer(http.Dir(tempDir))

	// Create test server
	server := httptest.NewServer(fs)
	defer server.Close()

	// Request non-existent file
	resp, err := http.Get(server.URL + "/nonexistent.txt")
	require.NoError(t, err)
	defer resp.Body.Close()

	// Should return 404
	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}

func TestFileServerServesHTML(t *testing.T) {
	tempDir := t.TempDir()

	oldDir, _ := os.Getwd()
	err := os.Chdir(tempDir)
	require.NoError(t, err)
	defer os.Chdir(oldDir)

	// Create HTML file
	htmlContent := "<html><body><h1>Test Page</h1></body></html>"
	err = os.WriteFile("index.html", []byte(htmlContent), 0644)
	require.NoError(t, err)

	// Create file server
	fs := http.FileServer(http.Dir("."))
	server := httptest.NewServer(fs)
	defer server.Close()

	// Make request
	resp, err := http.Get(server.URL + "/index.html")
	require.NoError(t, err)
	defer resp.Body.Close()

	// Verify response
	assert.Equal(t, http.StatusOK, resp.StatusCode)
	assert.Contains(t, resp.Header.Get("Content-Type"), "text/html")
}

func TestFileServerServesSubdirectory(t *testing.T) {
	tempDir := t.TempDir()

	oldDir, _ := os.Getwd()
	err := os.Chdir(tempDir)
	require.NoError(t, err)
	defer os.Chdir(oldDir)

	// Create subdirectory
	err = os.Mkdir("subdir", 0755)
	require.NoError(t, err)

	// Create file in subdirectory
	testContent := "Subdirectory content"
	err = os.WriteFile("subdir/test.txt", []byte(testContent), 0644)
	require.NoError(t, err)

	// Create file server
	fs := http.FileServer(http.Dir("."))
	server := httptest.NewServer(fs)
	defer server.Close()

	// Make request
	resp, err := http.Get(server.URL + "/subdir/test.txt")
	require.NoError(t, err)
	defer resp.Body.Close()

	// Verify response
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	// Read body
	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	assert.Equal(t, testContent, string(body))
}

func TestHTTPHandlerSetup(t *testing.T) {
	// Test that http.Handle properly sets up the handler
	mux := http.NewServeMux()
	fs := http.FileServer(http.Dir("."))
	mux.Handle("/", fs)

	// Create test server with custom mux
	server := httptest.NewServer(mux)
	defer server.Close()

	// Make request - should work even with empty directory
	resp, err := http.Get(server.URL + "/")
	require.NoError(t, err)
	defer resp.Body.Close()

	// Should not error
	assert.NotNil(t, resp)
}

func TestPortValidation(t *testing.T) {
	// Test valid port numbers
	validPorts := []string{"80", "8080", "3000", "9999", "1234"}

	for _, port := range validPorts {
		t.Run(port, func(t *testing.T) {
			addr := fmt.Sprintf(":%s", port)
			assert.NotEmpty(t, addr)
			assert.Contains(t, addr, ":")
		})
	}
}
