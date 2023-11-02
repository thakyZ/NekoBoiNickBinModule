import hashlib
import os
import argparse

parser = argparse.ArgumentParser(description="Outputs the hashes of all subdirectories of target.")
parser.add_argument("--silent", action="store_true", help="Disables console output.")
parser.add_argument("--rootdir", type=str, help="The target directory.")
parser.add_argument("--file", type=str, help="Output file.")
parser.add_argument("--open", action="store_true", help="Opens file upon completion.")
parser.add_argument("--force", action="store_true", help="Overwrite without prompt.")
parser.add_argument("--algorithm", type=str, help="The hashing library to use.")


args = parser.parse_args()

rootdir = args.rootdir or "C:\\Program Files (x86)\\Steam\\steamapps\\workshop\\content\\281990"

def hash_directory(path,lib):
    digest = hashlib.new(lib)

    for root, dirs, files in os.walk(path):
        for names in files:
            file_path = os.path.join(root, names)

            digest.update(hashlib.sha1(file_path[len(path):].encode()).digest())

            if os.path.isfile(file_path):
                with open(file_path, 'rb') as f_obj:
                    while True:
                        buf = f_obj.read(1024 * 1024)
                        if not buf:
                            break
                        digest.update(buf)
    return digest.hexdigest()


lib = args.algorithm or 'md5'

algorithms_available = hashlib.algorithms_available - {'shake_128','shake_256'}

if lib not in algorithms_available:
    print("\"" + lib + "\" algorithm not found. Available algorithms are [" + ', '.join(algorithms_available) + ']')
    quit()

if args.file:
    if not args.force and os.path.exists(args.file) and input("The file \"" + args.file + "\" already exists, would you like to overwrite? [y/n] ").lower() != 'y':
            quit()
    text_file = open(args.file, "w")

for dir in os.scandir(rootdir):
    line = dir.name + " " + hash_directory(dir.path,lib)
    if dir.is_dir():
        if not args.silent:
            print(line)
        if args.file:
            text_file.write(line + "\n")

if args.file:
    text_file.close()
    if args.open:
        os.startfile(args.file)