# Fetch GitIgnore

GitHub keeps a [repository of gitignore](https://github.com/github/gitignore) files for various programming languages and frameworks. This tool grabs gitignore files based on the arguments passed in. One or more languages/framework names can be passed in to the tool to grab a gitignore that incorporates all of them.

The gitignore will be placed in the directory that the tool is called in. If there is already a gitignore, the additionally ignored list will be appended to that file.

Example:

```sh
# Fetch a gitignore for Python
fetch-gitignore Python

# Fetch a gitignore for Rust and Zig
fetch-gitignore Rust Zig
```

This tool naively matches against the file names in the GitHub repository. For a full list of gitignores that can be used, refer to the [repository itself](https://github.com/github/gitignore).
