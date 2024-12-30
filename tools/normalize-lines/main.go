package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"
)

func main() {
	// Define a flag for breakLength with a default value of 80
	breakLengthFlag := flag.Int("breaklength", 80, "The maximum length of each line before breaking")
	flag.Parse()

	var inputBuffer bytes.Buffer
	_, err := io.Copy(&inputBuffer, os.Stdin)
	if err != nil {
		fmt.Println("Error reading input:", err)
		os.Exit(1)
	}
	text := inputBuffer.String()

	// Normalize text with the specified breakLength
	fmt.Print(normalize(text, *breakLengthFlag))
}

// normalize breaks the input text into lines without breaking words
// Each line will not exceed the given breakLength
func normalize(text string, breakLength int) string {
	var lines []string
	var builder strings.Builder

	for _, unit := range splitAndRetainWhitespace(text) {
		if builder.Len()+len(unit) > breakLength || unit == "\n" {
			lines = append(lines, strings.TrimSpace(builder.String()))
			builder.Reset()
		}

		if unit != "\n" {
			builder.WriteString(unit)
		}
	}

	// Append the last line (if any)
	if builder.Len() > 0 {
		lines = append(lines, builder.String())
	}

	// Join all the lines with newlines between them
	return strings.Join(lines, "\n")
}

// splitAndRetainWhitespace splits a string on any whitespace characters
// It returns a slice of strings where alternating values are words and whitespace.
// For example, "Hello   World " would return []string{"Hello", "   ", "World", " "}.
func splitAndRetainWhitespace(text string) []string {
	re := regexp.MustCompile(`\S+|(\n|\r\n|\s+)`) // Match sequences of non-whitespace and the whitespace that follows them.

	return re.FindAllString(text, -1)
}
