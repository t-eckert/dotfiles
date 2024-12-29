package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	var prepend string
	flag.StringVar(&prepend, "prepend", "", "string to prepend to all files in the glob")
	flag.Parse()

	globs := flag.Args()
	if len(globs) == 0 {
		fmt.Println("No glob patterns provided.")
		os.Exit(1)
	}

	files, err := fetchAllFiles(globs)
	if err != nil {
		fmt.Println("Error fetching files:", err)
		os.Exit(1)
	}

	fileRenames := prependString(files, prepend)

	err = renameFiles(fileRenames)
	if err != nil {
		fmt.Println("Error renaming files:", err)
		os.Exit(1)
	}
}

// fetchAllFiles returns the names of all files matching the given globs.
func fetchAllFiles(globs []string) ([]string, error) {
	var files []string
	for _, glob := range globs {
		matches, err := filepath.Glob(glob)
		if err != nil {
			return nil, err
		}
		files = append(files, matches...)
	}
	return files, nil
}

// prependString returns a slice of tuples of the original filenames
// and the filenames with the prepend added.
func prependString(files []string, prepend string) [][2]string {
	var fileRenames [][2]string
	for _, file := range files {
		fileRenames = append(fileRenames, [2]string{file, prepend + file})
	}
	return fileRenames
}

// renameFiles iterates over the file rename tuples and renames the files accordingly.
func renameFiles(fileRenames [][2]string) error {
	for _, fileRename := range fileRenames {
		err := os.Rename(fileRename[0], fileRename[1])
		if err != nil {
			return err
		}
	}
	return nil
}
