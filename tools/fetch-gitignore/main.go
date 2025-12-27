package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

const (
	source = "https://raw.githubusercontent.com/github/gitignore/main/%s.gitignore"
	target = ".gitignore"
)

func main() {
	langs := os.Args[1:]

	var ignoreList string
	for _, lang := range langs {
		data, err := fetch(lang)
		if err != nil {
			log.Fatalf("Failed to fetch .gitignore for %s: %v", lang, err)
		}
		ignoreList += string(data) + "\n"
	}

	if err := write(target, ignoreList); err != nil {
		log.Fatalf("Failed to write to .gitignore: %v", err)
	}
}

func fetch(lang string) ([]byte, error) {
	resp, err := http.Get(fmt.Sprintf(source, lang))
	if err != nil {
		return nil, fmt.Errorf("error fetching .gitignore: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("error fetching .gitignore: %s", resp.Status)
	}

	return io.ReadAll(resp.Body)
}

func write(target, content string) error {
	file, err := os.OpenFile(target, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("error opening .gitignore: %w", err)
	}
	defer file.Close()

	_, err = file.WriteString(content)
	if err != nil {
		return fmt.Errorf("failed to write to file: %w", err)
	}
	return nil
}
