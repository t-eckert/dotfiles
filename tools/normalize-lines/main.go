package main

import (
	"flag"
	"fmt"
	"strings"
)

func main() {
	// Define a flag for breakLength with a default value of 80
	breakLengthFlag := flag.Int("breaklength", 80, "The maximum length of each line before breaking")
	flag.Parse()

	// Join the remaining arguments into a single string
	text := strings.Join(flag.Args(), " ")

	// Normalize text with the specified breakLength
	fmt.Print(normalize(text, *breakLengthFlag))
}

// normalize breaks the input text into lines without breaking words
// Each line will not exceed the given breakLength
func normalize(text string, breakLength int) string {
	var lines []string
	var builder strings.Builder

	// Split the input text into words, preserving spaces where needed
	words := strings.Fields(text) // This splits on any whitespace and removes excess spaces

	for _, word := range words {
		// Check if adding the word to the builder would exceed the line length
		if builder.Len()+len(word)+1 > breakLength { // +1 for the space
			// If it would, finish the current line and start a new one
			lines = append(lines, builder.String())
			builder.Reset()
		}

		// Add the word to the current line
		if builder.Len() > 0 {
			builder.WriteString(" ") // Add space between words
		}
		builder.WriteString(word)
	}

	// Append the last line (if any)
	if builder.Len() > 0 {
		lines = append(lines, builder.String())
	}

	// Join all the lines with newlines between them
	return strings.Join(lines, "\n")
}
