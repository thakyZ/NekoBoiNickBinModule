#!/usr/bin/env python3
"""Module"""
# cSpell:ignore rootdir startfile steamapps scandir
import hashlib
import os
import argparse
import sys
from typing import Set, cast
import xxhash

parser = argparse.ArgumentParser(
    description="Outputs the hashes of all subdirectories of target.")
parser.add_argument("--silent", action="store_true",
                    help="Disables console output.")
parser.add_argument("--rootdir", type=str, help="The target directory.")
parser.add_argument("--file", type=str, help="Output file.")
parser.add_argument("--single", action="store_true")
parser.add_argument("--open", action="store_true",
                    help="Opens file upon completion.")
parser.add_argument("--force", action="store_true",
                    help="Overwrite without prompt.")
parser.add_argument("--algorithm", type=str,
                    help="The hashing library to use.")


args = parser.parse_args()

rootdir: str = args.rootdir or \
    "C:\\Program Files (x86)\\Steam\\steamapps\\workshop\\content\\281990"


def get_digest(lib1: str):
    """Method"""
    if lib1 == "xxh32":
        return xxhash.xxh32()
    if lib1 == "xxh64":
        return xxhash.xxh64()
    return hashlib.new(lib1)


def hash_directory(path: str, lib2: str):
    """Method"""
    digest = get_digest(lib2)

    for root, _, files in os.walk(path):
        for names in files:
            file_path = os.path.join(root, names)

            digest.update(hashlib.sha1(
                file_path[len(path):].encode()).digest())

            if os.path.isfile(file_path):
                with open(file_path, 'rb') as f_obj:
                    while True:
                        buf = f_obj.read(1024 * 1024)
                        if not buf:
                            break
                        digest.update(buf)
    return digest.hexdigest()


lib = args.algorithm or 'xxh64'

algorithms_available: Set[str] = (cast(Set[str], hashlib.algorithms_available) - {
    "shake_128", "shake_256"}).union({"xxh32", "xxh64"})

if lib not in algorithms_available:
    print(" ".join({
        f"\"{lib}\" algorithm not found. Available algorithms are ",
        f"[{', '.join(algorithms_available)}]"
    }))
    sys.exit(1)

if args.file:
    if not args.force and os.path.exists(args.file) and \
            input(f"The file \"{args.file}\" already exists, would you like to overwrite? [y/n] ") \
            .lower() != "y":
        sys.exit(1)
    with open(args.file, "w", encoding="utf-8") as text_file:
        if args.single:
            line = f"{os.path.basename(rootdir)},{hash_directory(rootdir, lib)}"
            if not args.silent:
                print(line)
            if args.file:
                text_file.write(line + "\n")
        else:
            for dir1 in os.scandir(rootdir):
                line = f"{dir1.name, hash_directory(dir1.path, lib)}"
                if dir1.is_dir():
                    if not args.silent:
                        print(line)
                    if args.file:
                        text_file.write(line + "\n")

        if args.file:
            text_file.close()
            if args.open:
                os.startfile(args.file)
