# Normalize Lines

This utility is made to be used in Vim, but can be used anywhere. It accepts a
string of text and re-normalizes the lines in the text to be 80 characters long
without breaking words.

The "breaklength" can be configured by passing `--breaklength <int>`. For example,
to break at 120 characters use `--breaklength 120`.
