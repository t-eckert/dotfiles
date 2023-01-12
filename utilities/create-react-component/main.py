import os

from sys import argv

def main(name: str):
    create_directory(name)
    create_index(name)
    create_stories(name)
    create_component(name)

def create_directory(name: str):
    os.path.exists(name) or os.mkdir(name)

def create_index(name: str):
    with open(f"{name}/index.ts", "w") as file:
        file.write(f"""import {name} from "./{name}
export default {name}""")

def create_stories(name: str):
    with open(f"{name}/{name}.stories.tsx", "w") as file:
        file.write(f"""import {{ ComponentStory, ComponentMeta }} from "@storybook/react"
import {name}, {{ Props }} from "./{name}"

export default {{
    title: "components/{name}",
    component: {name},
}} as ComponentMeta<typeof {name}>

const Component: ComponentStory<typeof {name}> = (args) => <{name} {{...args}} />

export const Default = Component.bind({{}})
Default.args = {{}} as Props""")

def create_component(name: str):
    with open(f"{name}/{name}.tsx", "w") as file:
        file.write(f"""export interface {name} {{
}}

const {name}: React.FC<Props> = ({{}}) => {{
    return <div>{name}</div>
}}
 
export default {name}""")

if __name__ == "__main__":
    if len(argv) < 2:
        print("Please enter the component name.")
        exit(1)

    name = argv[1] 
    main(name)
