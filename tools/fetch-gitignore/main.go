package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
)

const (
	source = "https://raw.githubusercontent.com/github/gitignore/master/%s.gitignore"
	target = ".gitignore"
)

func main() {
	var lang string
	flag.StringVar(&lang, "lang", "", "language to fetch .gitignore for")
	flag.Parse()

	resp, err := http.Get(fmt.Sprintf(source, lang))
	if err != nil {
		fmt.Println("Error fetching .gitignore:", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		fmt.Println("Error fetching .gitignore:", resp.Status)
		os.Exit(1)
	}

	file, err := os.OpenFile(target, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Println("Error opening .gitignore:", err)
		os.Exit(1)
	}
	defer file.Close()

	_, err = io.Copy(file, resp.Body)
	if err != nil {
		fmt.Println("Failed to write to file", err)
		os.Exit(1)
	}
}
