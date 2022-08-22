package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	text := strings.Join(os.Args[1:], " ")
	fmt.Print(Normalize(text, 80))
}

func Normalize(text string, breakLength int) string {
	lines := []string{}
	var builder strings.Builder
	for _, word := range strings.Split(strings.ReplaceAll(text, "\n", " "), " ") {
		if builder.Len()+len(word) > breakLength {
			lines = append(lines, strings.TrimRight(builder.String(), " "))
			builder.Reset()
		}
		builder.WriteString(word + " ")
	}

	lines = append(lines, strings.TrimRight(builder.String(), " "))

	return strings.Join(lines, "\n")
}
