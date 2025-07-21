package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("Usage: %s <file(s) or glob>\n", os.Args[0])
		os.Exit(1)
	}

	for _, arg := range os.Args[1:] {
		matches, err := filepath.Glob(arg)
		if err != nil {
			fmt.Printf("Error processing glob '%s': %v\n", arg, err)
			continue
		}

		if len(matches) == 0 {
			fmt.Printf("Error: '%s' is not a valid file or glob\n", arg)
			continue
		}

		for _, match := range matches {
			fileInfo, err := os.Stat(match)
			if err != nil {
				fmt.Printf("Error getting info for '%s': %v\n", match, err)
				continue
			}

			if !fileInfo.IsDir() {
				renameFileToKebabCase(match)
			}
		}
	}
}

func toKebabCase(s string) string {
	// Convert string to lowercase
	lowerStr := strings.ToLower(s)
	// Replace non-alphanumeric characters with a dash
	nonAlphanumeric := regexp.MustCompile(`[^a-zA-Z0-9]+`)
	kebab := nonAlphanumeric.ReplaceAllString(lowerStr, "-")
	// Trim dashes from the start and end
	return strings.Trim(kebab, "-")
}

func renameFileToKebabCase(path string) {
	directory, filename := filepath.Split(path)
	extension := filepath.Ext(filename)
	filenameNoExt := filename[0 : len(filename)-len(extension)]
	kebabCaseFilename := toKebabCase(filenameNoExt) + extension
	newPath := filepath.Join(directory, kebabCaseFilename)
	if err := os.Rename(path, newPath); err != nil {
		fmt.Printf("Error renaming '%s' to '%s': %v\n", filename, kebabCaseFilename, err)
	} else {
		fmt.Printf("Renamed '%s' to '%s'\n", filename, kebabCaseFilename)
	}
}
