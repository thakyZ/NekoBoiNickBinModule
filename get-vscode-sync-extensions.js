const fs = require("node:fs");
const path = require("node:path");
const process = require("node:process");

async function getDirectories(source) {
  const directoryContents = await fs.promises.readdir(source, { withFileTypes: true });
  return directoryContents.filter(dirent => dirent.isDirectory()).map(dirent => dirent.name)
}
async function getFiles(source, extensionMatch = undefined) {
  const directoryContents = await fs.promises.readdir(source, { withFileTypes: true });
  return directoryContents.filter((dirent) => {
    if (dirent.isFile()) {
      if (typeof extensionMatch === "string") {
        return dirent.name.endsWith(extensionMatch);
      }
      return true;
    }
    return false;
  }).map(dirent => dirent.name)
}

const compiledAllExtensions = [];

async function handleJsonFile(source) {
  const jsonContent = await fs.promises.readFile(source, { encoding: "utf8" });
  const json1 = JSON.parse(jsonContent);
  if (Object.hasOwn(json1, "content")) {
    const json2 = JSON.parse(json1.content);
    console.log(source, ":", "\n", JSON.stringify(json2, null, 2))
  } else {
    console.warn(`json file at "${source}" does not contain key "content" at root node.`)
  }
}

async function main() {
  const userAppData  = process.env["AppData"];
  const codeDataPath = path.join(userAppData, "Code");
  const codeUserPath = path.join(codeDataPath, "User");
  const codeUserSyncPath = path.join(codeUserPath, "sync");

  const syncedProfiles = await getDirectories(codeUserSyncPath);

  for (const profile of syncedProfiles) {
    const profileDir = path.join(codeUserSyncPath, profile);
    const profileExtensionsDir = path.join(profileDir, "extensions");
    if (fs.existsSync(profileExtensionsDir)) {
      const syncedExtensionsFiles = await getFiles(profileExtensionsDir, ".json");
      for (const syncedExtensionsFile of syncedExtensionsFiles) {
        await handleJsonFile(path.join(profileExtensionsDir, syncedExtensionsFile));
      }
    }
  }
}

main();

// C:\Users\thaky\AppData\Roaming\Code\User\settings.json