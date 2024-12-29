package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"time"

	"github.com/jedib0t/go-pretty/v6/table"
)

func main() {
	if len(os.Args) == 1 {
		log.Fatal("No arguments provided. Pass the path to a JSON configuration.")
	}

	path := os.Args[1]
	if path[len(path)-5:] != ".json" {
		log.Fatal("The file must be a JSON file.")
	}

	config, err := LoadConfig(path)
	if err != nil {
		log.Fatal(err)
	}

	if err = printTeamTime(*config); err != nil {
		log.Fatal(err)
	}
}

type Teammember struct {
	Name string `json:"name"`
	Tz   string `json:"tz"`
}

func LoadConfig(filename string) (*[]Teammember, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	byteValue, _ := ioutil.ReadAll(file)
	var teammembers []Teammember
	json.Unmarshal(byteValue, &teammembers)

	for i := range teammembers {
		teammembers[i].Tz = strings.ReplaceAll(teammembers[i].Tz, " ", "_")
	}

	return &teammembers, nil
}

func printTeamTime(teammembers []Teammember) error {
	now := time.Now()

	t := table.NewWriter()
	t.SetStyle(table.StyleRounded)
	t.SetOutputMirror(os.Stdout)
	t.AppendHeader(table.Row{"Name", "Time"})

	for _, tm := range teammembers {
		tz, err := time.LoadLocation(tm.Tz)
		if err != nil {
			return err
		}

		displayTime := now.In(tz).Format("03:04 PM MST")
		if displayTime[0] == '0' {
			displayTime = " " + displayTime[1:]
		}

		t.AppendRow(table.Row{tm.Name, displayTime})
	}

	t.Render()
	return nil
}
