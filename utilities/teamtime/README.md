# `teamtime`

A command line application that tells you what time is is for everyone on your team.

## Installation

``` bash
go install github.com/t-eckert/teamtime
```

## Usage

Pass in a `JSON` file with your team members' names and their timezones.

``` json
// teammembers.json
[
  {
    "name": "John Doe",
    "tz": "America/Los Angeles"
  },
  {
    "name": "Jane Doe",
    "tz": "America/New York"
  }
]
```

``` bash
teamtime teammembers.json
```

``` text
╭──────────┬──────────────╮
│ NAME     │ TIME         │
├──────────┼──────────────┤
│ John Doe │ 01:18 PM PDT │
│ Jane Doe │ 04:18 PM EDT │
╰──────────┴──────────────╯
```
