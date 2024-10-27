#!/usr/bin/env python3

"""Compare Script"""

import os
from pathlib import Path
import sys
from argparse import ArgumentParser, Namespace
from typing import Any

def write(text_file: Path | None, key_values: list[tuple[bool, str, str]]):
    """Writes the given key_values to a given file or prints if no file specified.

    Args:
        text_file (Path | None): The file to write to.
        key_values (list[tuple[str, str]]): the given keys that were compared.
    """
    lines: list[str] = []
    for value in key_values:
        operator: str = ""
        if value[0] is True:
            operator = "=="
        elif value[0] is False:
            operator = "!="
        lines.append(f"{value[1]} {operator} {value[2]}\n")
    if isinstance(text_file, Path):
        with text_file.open("w", encoding="utf8") as fw:
            fw.writelines(lines)
    else:
        for line in lines:
            print(line)

def process(dict_a: dict[str, Any], dict_b: dict[str, Any]) -> list[tuple[bool, str, str]]:
    """Processes the dictionaries and outputs them.

    Args:
        args (Namespace): Args passed to the CLI
        dict_a (dict[str, Any]): The first dictionary.
        dict_b (dict[str, Any]): The second dictionary.
    """
    key_values: list[tuple[bool, str, str]] = []
    for key_a, value_a in dict_a.items():
        for key_b, value_b in dict_b.items():
            _tuple: tuple[bool, str, str]
            if key_a == key_b and value_a != value_b:
                _tuple = (False, key_a, key_b)
                key_values.append(_tuple)
            if key_a == key_b and value_a == value_b:
                _tuple = (True, key_a, key_b)
                key_values.append(_tuple)
    return key_values

def main() -> None:
    """Main method"""

    parser = ArgumentParser(description="Outputs the hashes of all subdirectories of target.")
    parser.add_argument("--silent", action="store_true", help="Disables console output.")
    parser.add_argument("--fileA", type=str, help="Input file A.")
    parser.add_argument("--fileB", type=str, help="Input file B.")
    parser.add_argument("--output", type=str, help="Output file.")
    parser.add_argument("--open", action="store_true", help="Opens file upon completion.")
    parser.add_argument("--force", action="store_true", help="Overwrite without prompt.")

    args: Namespace = parser.parse_args()

    path_a: Path = Path(args.fileA or "fileA.txt")
    path_b: Path = Path(args.fileB or "fileB.txt")
    dict_a: dict[str, Any] = {}
    dict_b: dict[str, Any] = {}

    with path_a.open("r", encoding="utf8") as file_a:
        for line in file_a.readlines():
            split = line.split(",")
            dict_a[split[0]] = split[1][:-1]
        file_a.close()

    with path_b.open("r", encoding="utf8") as file_b:
        for line in file_b.readlines():
            split = line.split(",")
            dict_b[split[0]] = split[1][:-1]
        file_b.close()

    text_file: Path | None = None
    if args.output:
        if (not args.force and Path(args.output).exists() and
            input(f"The file \"{args.output}\" already exists"
                  ", would you like to overwrite? [y/n] ").lower() != 'y'):
            sys.exit(0)
        else:
            text_file = Path(args.output)
            with text_file.open("w", encoding="utf8") as fw:
                fw.truncate(0)

    key_values: list[tuple[bool, str, str]] = process(dict_a, dict_b)

    if args.output and isinstance(text_file, Path):
        write(text_file, key_values)
        if args.open:
            os.startfile(args.output)
    elif not args.silent or not args.output:
        write(None, key_values)

if __name__ == "__main__":
    main()
