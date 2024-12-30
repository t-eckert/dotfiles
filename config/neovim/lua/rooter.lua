-- When setting the root of a project, rooter will look for these files.
require("nvim-rooter").setup {
	rooter_patterns = {
		".git",
		"Makefile",
		"*.sln",
		"build/env.sh",
		".venv/",
		".gitignore",
		"go.mod"
	},
}
