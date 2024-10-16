#!/usr/bin/python3

"""A python script (outdated) to fix the BD plugin "FavoriteMedia"."""

import os
import sys
import json
from typing import Any, TypeAlias
from urllib import request
from urllib.request import URLopener
from urllib.error import HTTPError
import math
from pathlib import Path
import shutil
from email.message import Message
from PIL import Image

FAVORITE_MEDIA_CONFIG: str = "FavoriteMedia.config.json"
USER_AGENT: str = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko"
                  ") Chrome/111.0.0.0 Safari/537.36")
TEMP_PNG: str = "temp.png"

Json: TypeAlias = Any
URLopenerRetrieve: TypeAlias = tuple[str, Message| None]
Dimensions: TypeAlias = tuple[int, int]
ProcessFile: TypeAlias = tuple[URLopenerRetrieve, Dimensions]

def get_env_var(env_var: str) -> str:
    """Safely gets the env variable's value

    Args:
        env_var (str): The environment variable to get the value of.

    Raises:
        EnvironmentError: Raises if the environment variable could not be found.

    Returns:
        str: The environment variable's value
    """
    temp: str | None = os.getenv(env_var)
    if temp is None:
        raise EnvironmentError(f"Unable to get environment variable \"{env_var}\"")
    return temp


def print_error(message: str, error: BaseException | Exception | HTTPError) -> None:
    """Prints an error to the console taking into account types of Exceptions

    Args:
        message (str): The message to display
        error (BaseException | Exception | HTTPError): The exception to print
    """
    if isinstance(error, HTTPError):
        print(f"{message} (code {str(error.code)})\n{str(error)}")
    else:
        print(f"{message}\n{str(error)}")


def retrieve_file(image_url: str, temp_image: Path) -> URLopenerRetrieve | None:
    """Get the file via a url request.

    Args:
        image_url (str): The url to the image.
        temp_image (Path): the path to the output image file.

    Returns:
        tuple[str, Message[str, str] | None]: Returns the output of URLopener.retrieve()
        None:                                 Returns if there is an issue retrieving the file.
    """
    output: URLopenerRetrieve | None = None
    try:
        opener: URLopener = URLopener()
        _tuple: tuple[str, str] = ("User-Agent", USER_AGENT)
        opener.addheader(_tuple)
        output = opener.retrieve(image_url, str(temp_image))
        opener.close()
    except HTTPError as http_error:
        print_error(f"Failed to retrieve image at url: {image_url}", http_error)
    except Exception as error:
        print_error(f"Failed to retrieve image at url: {image_url}", error)
    except BaseException as berror:
        print_error(f"Failed to retrieve image at url: {image_url}", berror)
    request.urlcleanup()
    return output

def get_dimensions(temp_image: Path) -> Dimensions | None:
    """Gets the dimensions safely of the image at the given path.

    Args:
        temp_image (Path): The path of the image to get the image of

    Returns:
        Dimensions: Returns the dimensions of the image
        None:       Returns if there is an issue reading the file or its dimensions.
    """
    try:
        with Image.open(temp_image) as im:
            _tuple: tuple[int, int] = (im.width, im.height)
            return _tuple
    except Exception as error:
        print_error(f"Failed to open image at path: {temp_image}", error)
    except BaseException as berror:
        print_error(f"Failed to open image at path: {temp_image}", berror)
    return None

def process_image(
    index: int,
    data : Json | None,
    dimensions: Dimensions,
    ratio_const: int = 350,
    const_height: int | None = None) -> bool:
    """_summary_

    Args:
        index (int): _description_
        data (Json | None): _description_
        dimensions (Dimensions): _description_
        ratio_const (int, optional): _description_. Defaults to 350.
        const_height (int | None, optional): _description_. Defaults to None.

    Returns:
        bool: _description_
    """
    if data is None:
        return False
    w, h = dimensions
    ratio: float = ratio_const / h
    new_width: int = math.floor(w * ratio)
    data["image"]["medias"][index]["width"] = new_width
    if const_height is not None:
        data["image"]["medias"][index]["height"] = 350
    return True


def process_file(image_url: str, temp_image: Path) -> ProcessFile | None:
    """_summary_

    Args:
        image_url (str): _description_
        temp_image (Path): _description_

    Returns:
        tuple[URLopenerRetrieve, tuple[int, int]] | None: _description_
    """
    request: URLopenerRetrieve | None = retrieve_file(image_url, temp_image)
    if request is None:
        return None
    dimensions: Dimensions | None = get_dimensions(temp_image)
    if dimensions is None:
        return None
    return (request, dimensions)


def process_data(data: Json, temp_path: Path) -> bool:
    """_summary_

    Args:
        data (Json): _description_
        temp_path (Path): _description_

    Returns:
        _type_: _description_
    """
    wrote: bool = False
    temp_image: Path = Path(temp_path, TEMP_PNG)
    for index, image in enumerate(data["image"]["medias"]):
        if image["width"] == "calc(100 % + 1px)" or (image["width"] == 0 and image["height"] != 0):
            output: ProcessFile | None = process_file(image["url"], temp_image)
            if output is not None and process_image(index, data, output[1], ratio_const=image["height"]):
                wrote = True
        elif (image["width"] == 0 and image["height"] == 0) or (image["width"] != 0 and image["height"] == 0):
            output: ProcessFile | None = process_file(image["url"], temp_image)
            if output is not None and process_image(index, data, output[1], const_height=350):
                wrote = True
    return wrote


def handle_files(temp_path: Path) -> None:
    """Handles the creation and deletion of files.

    Args:
        temp_path (Path): The path to the temp directory.
    """
    if temp_path.exists():
        try:
            shutil.rmtree(temp_path)
        except Exception as error:
            print_error("Failed to delete already existing temp directory", error)
            sys.exit(1)
        except BaseException as berror:
            print_error("Failed to delete already existing temp directory", berror)
            sys.exit(1)

    if not temp_path.exists():
        try:
            os.mkdir(temp_path, 0o666)
        except Exception as error:
            print_error("Failed to create temp directory", error)
            sys.exit(1)
        except BaseException as berror:
            print_error("Failed to create temp directory", berror)
            sys.exit(1)


def main() -> None:
    """The main method of this script"""

    bd_dir: Path | None = None
    temp_path: Path = Path(get_env_var("TEMP"), "Fix-FavoriteMedia")

    if os.name == 'nt':
        bd_dir = Path(get_env_var("APPDATA"), "BetterDiscord", "plugins")
    else:
        bd_dir = Path(get_env_var("HOME"), ".local", "BetterDiscord", "plugins")

    config_file: Path = Path(bd_dir, FAVORITE_MEDIA_CONFIG)

    if not config_file.exists():
        print(f"The {FAVORITE_MEDIA_CONFIG} does not exist")
        sys.exit(1)

    data: Json | None = None

    handle_files(temp_path)

    with Path(bd_dir, FAVORITE_MEDIA_CONFIG).open("r", encoding="utf8") as openfile:
        data = json.load(openfile)

    wrote: bool = False

    if data != {} and data is not None:
        wrote = process_data(data, temp_path)

    if wrote:
        with config_file.open("w", encoding="utf8") as outfile:
            outfile.write(json.dumps(data, indent=4))

    if temp_path.exists():
        try:
            shutil.rmtree(temp_path)
        except Exception as error:
            print(f"Failed to clean temp directory: {str(error)}")
            sys.exit(1)
        except BaseException as berror:
            print(f"Failed to clean temp directory: {str(berror)}")
            sys.exit(1)

if __name__ == "__main__":
    main()
