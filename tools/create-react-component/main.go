package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Please enter the component name.")
		os.Exit(1)
	}
	name := os.Args[1]
	createDirectory(name)
	createIndex(name)
	createStories(name)
	createComponent(name)
}

func createDirectory(name string) {
	if _, err := os.Stat(name); os.IsNotExist(err) {
		os.Mkdir(name, 0755)
	}
}

func createIndex(name string) {
	content := fmt.Sprintf(`import %s from "./%s"
export default %s`, name, name, name)
	writeToFile(filepath.Join(name, "index.ts"), content)
}

func createStories(name string) {
	content := fmt.Sprintf(`import { ComponentStory, ComponentMeta } from "@storybook/react"
import %s, { Props } from "./%s"

export default {
    title: "components/%s",
    component: %s,
} as ComponentMeta<typeof %s>

const Component: ComponentStory<typeof %s> = (args) => <%s {...args} />

export const Default = Component.bind({})
Default.args = {} as Props`, name, name, name, name, name, name, name)
	writeToFile(filepath.Join(name, fmt.Sprintf("%s.stories.tsx", name)), content)
}

func createComponent(name string) {
	content := fmt.Sprintf(`export interface Props {
}

const %s: React.FC<Props> = ({}) => {
    return <div>%s</div>
}

export default %s`, name, name, name)
	writeToFile(filepath.Join(name, fmt.Sprintf("%s.tsx", name)), content)
}

func writeToFile(filename, content string) {
	file, err := os.Create(filename)
	if err != nil {
		fmt.Println("Error creating file:", err)
		return
	}
	defer file.Close()

	_, err = file.WriteString(content)
	if err != nil {
		fmt.Println("Error writing to file:", err)
	}
}
