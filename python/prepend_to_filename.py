"""Prepend the given string to all files in the glob"""

from pathlib import Path
from typing import Iterable

import argparse
import os


def fetch_all_files(globs: Iterable[str]) -> list[str]:
    # Return the names of all files matching the given globs
    return [str(file) for glob in globs for file in Path(".").glob(glob)]


def prepend_string(files: list[str], prepend: str) -> list[tuple[str, str]]:
    # Returns a tuple of the original filenames and the filenames with the prepend added
    return [(file, prepend + file) for file in files]


def rename_files(file_renames: list[tuple[str, str]]):
    # Iterates over the file rename tuples and renames the files accordingly
    for file_rename in file_renames:
        os.rename(file_rename[0], file_rename[1])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Prepend the given string to all files in the glob"
    )
    parser.add_argument(
        "prepend", type=str, help="string to prepend to all files in the glob"
    )
    parser.add_argument("glob", nargs=argparse.REMAINDER, type=str, help="glob of files to prepend to")

    args = parser.parse_args()

    rename_files(prepend_string(fetch_all_files(args.glob), args.prepend))


def test_fetch_all_files():
    filetype = "d47a29ec-defe-4f8d-8e01-84662db038c6"
    file = "f726c1f3-0cf3-4142-a94b-7d00e66cb978." + filetype

    with open(file, "w") as _:
        pass

    expected = [file]

    globs = ["*." + filetype]

    actual = fetch_all_files(globs)

    os.remove(file)

    assert expected == actual


def test_prepend_string():
    files = ["water.md", "cider.md"]
    prepend = "sparkling-"

    expected = [("water.md", "sparkling-water.md"), ("cider.md", "sparkling-cider.md")]

    actual = prepend_string(files, prepend)

    assert expected == actual


def test_rename_files():
    name = "408eeaa9-3a38-4118-af0a-03865433386b"
    rename = "prepend-" + name

    with open(name, "w") as _:
        pass

    rename_files([(name, rename)])

    try:
        actual = str(next(Path(".").glob(rename)))
        os.remove(rename)
    except StopIteration as e:
        print(e)
        actual = ""
        os.remove(name)

    assert rename == actual
