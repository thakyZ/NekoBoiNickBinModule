#!/usr/bin/env python3

"""Stellaris Hasher Code"""

# cSpell:ignore root_dir startfile steamapps scandir
import hashlib
from io import TextIOWrapper
import os
from argparse import ArgumentParser, Namespace
from pathlib import Path
import sys
from typing import Set, cast
import xxhash

def get_digest(lib: str):
    """Method"""
    if lib == "xxh32":
        return xxhash.xxh32()
    if lib == "xxh64":
        return xxhash.xxh64()
    return hashlib.new(lib)


def hash_directory(path: Path, lib: str):
    """Method"""
    digest = get_digest(lib)

    for root, _, files in os.walk(path):
        for names in files:
            file_path = os.path.join(root, names)

            digest.update(hashlib.sha1(
                file_path[len(str(path)):].encode()).digest())

            if os.path.isfile(file_path):
                with open(file_path, 'rb') as f_obj:
                    while True:
                        buf = f_obj.read(1024 * 1024)
                        if not buf:
                            break
                        digest.update(buf)
    return digest.hexdigest()

def scan_directory(text_file: TextIOWrapper, args: Namespace, root_dir: Path, lib: str) -> None:
    """Method"""
    for directory in os.scandir(root_dir):
        line_str: str = f"{directory.name, hash_directory(Path(directory.path), lib)}"
        if directory.is_dir():
            if not args.silent:
                print(line_str)
            if args.file:
                text_file.write(line_str + "\n")

def handle_method(args: Namespace, root_dir: Path, lib: str) -> None:
    """Method"""
    with open(args.file, "w", encoding="utf-8") as text_file:
        if args.single:
            line_str: str = f"{os.path.basename(root_dir)},{hash_directory(root_dir, lib)}"
            if not args.silent:
                print(line_str)
            if args.file:
                text_file.write(line_str + "\n")
        else:
            scan_directory(text_file, args, root_dir, lib)

        if args.file:
            text_file.close()
            if args.open:
                os.startfile(args.file)

def main() -> None:
    """Method"""
    parser = ArgumentParser(description="Outputs the hashes of all subdirectories of target.")
    parser.add_argument("--silent", action="store_true", help="Disables console output.")
    parser.add_argument("--root_dir", type=str, help="The target directory.")
    parser.add_argument("--file", type=str, help="Output file.")
    parser.add_argument("--single", action="store_true")
    parser.add_argument("--open", action="store_true", help="Opens file upon completion.")
    parser.add_argument("--force", action="store_true", help="Overwrite without prompt.")
    parser.add_argument("--algorithm", type=str, help="The hashing library to use.")


    args = parser.parse_args()

    root_dir: Path = Path(args.root_dir) or \
        Path("C:\\Program Files (x86)\\Steam\\steamapps\\workshop\\content\\281990")

    if not root_dir.exists():
        raise FileNotFoundError(f"Direcctory in {root_dir} not found.")

    lib: str = args.algorithm or 'xxh64'

    algorithms_available: Set[str] = (cast(Set[str], hashlib.algorithms_available) - {"shake_128", "shake_256"}).union({"xxh32", "xxh64"})

    if lib not in algorithms_available:
        print(" ".join({
            f"\"{lib}\" algorithm not found. Available algorithms are ",
            f"[{', '.join(algorithms_available)}]"
        }))
        sys.exit(1)

    if args.file:
        if (not args.force
            and os.path.exists(args.file)
            and input(
                f"The file \"{args.file}\" already exists, would you like to overwrite? [y/n] ")
                .lower() != "y"
        ):
            sys.exit(1)
        handle_method(args, root_dir, lib)

if __name__ == "__main__":
    main()
