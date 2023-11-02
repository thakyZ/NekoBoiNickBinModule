#!/usr/bin/python3
import os
import json
import urllib.request
from urllib.error import HTTPError
from PIL import Image
import shutil
import math

bdDir = ""
tempPath = os.path.join(os.getenv("TEMP"), "Fix-FavoriteMedia")

if os.name == 'nt':
    bdDir = os.path.join(os.getenv("APPDATA"), "BetterDiscord", "plugins")
else:
    bdDir = os.path.join(os.getenv("HOME"), ".local",
                         "BetterDiscord", "plugins")

if not os.path.exists(os.path.join(bdDir, "FavoriteMedia.config.json")):
    print("The FavoriteMedia.config.json does not exist")
    exit

data = {}

if os.path.exists(tempPath):
    try:
        shutil.rmtree(tempPath)
    except:
        print("Failed to delete already existing temp directory")
        exit

if not os.path.exists(tempPath):
    try:
        os.mkdir(tempPath, 0o666)
    except:
        print("Failed to create temp directory")
        exit

with open(os.path.join(bdDir, "FavoriteMedia.config.json"), "r") as openfile:
    data = json.load(openfile)
    openfile.close()

wrote = False

if data != {}:
    for image in data["image"]["medias"]:
        if image["width"] == "calc(100 % + 1px)":
            try:
                opener = urllib.request.URLopener()
                opener.addheader(
                    "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36")
                opener.retrieve(
                    image["url"], os.path.join(tempPath, "temp.png"))
                opener.close()
            except HTTPError as error:
                print(
                    f"Failed to retrieve image at url: {image['url']} (code {str(error)})")
                continue
            urllib.request.urlcleanup()
            im = Image.open(os.path.join(tempPath, "temp.png"))
            w = im.width
            h = im.height
            im.close()
            ratio = image["height"] / h
            newWidth = math.floor(w * ratio)
            image["width"] = newWidth
            wrote = True
        elif image["width"] == 0 and image["height"] == 0:
            try:
                opener = urllib.request.URLopener()
                opener.addheader(
                    "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36")
                opener.retrieve(
                    image["url"], os.path.join(tempPath, "temp.png"))
                opener.close()
            except HTTPError as error:
                print(
                    f"Failed to retrieve image at url: {image['url']} (code {str(error)})")
                continue
            urllib.request.urlcleanup()
            im = Image.open(os.path.join(tempPath, "temp.png"))
            w = im.width
            h = im.height
            im.close()
            ratio = 350 / h
            newWidth = math.floor(w * ratio)
            image["width"] = newWidth
            image["height"] = 350
            wrote = True
        elif image["width"] == 0 and image["height"] != 0:
            try:
                opener = urllib.request.URLopener()
                opener.addheader(
                    "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36")
                opener.retrieve(
                    image["url"], os.path.join(tempPath, "temp.png"))
                opener.close()
            except HTTPError as error:
                print(
                    f"Failed to retrieve image at url: {image['url']} (code {str(error)})")
                continue
            urllib.request.urlcleanup()
            im = Image.open(os.path.join(tempPath, "temp.png"))
            w = im.width
            h = im.height
            im.close()
            ratio = image["height"] / h
            newWidth = math.floor(w * ratio)
            image["width"] = newWidth
            wrote = True
        elif image["width"] != 0 and image["height"] == 0:
            try:
                opener = urllib.request.URLopener()
                opener.addheader(
                    "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36")
                opener.retrieve(
                    image["url"], os.path.join(tempPath, "temp.png"))
                opener.close()
            except HTTPError as error:
                print(
                    f"Failed to retrieve image at url: {image['url']} (code {str(error)})")
                continue
            urllib.request.urlcleanup()
            im = Image.open(os.path.join(tempPath, "temp.png"))
            w = im.width
            h = im.height
            im.close()
            ratio = 350 / h
            newWidth = math.floor(w * ratio)
            image["width"] = newWidth
            image["height"] = 350
            wrote = True

if wrote:
    with open(os.path.join(bdDir, "FavoriteMedia.config.json"), "w") as outfile:
        outfile.write(json.dumps(data, indent=4))
        outfile.close()

if os.path.exists(tempPath):
    try:
        shutil.rmtree(tempPath)
    except Exception as error:
        print(f"Failed to clean temp directory: {str(error)}")
        exit
