(((pip list -o | Select-String -NotMatch "Package", "----------") -Replace '(?<name>[\w\d_]+).+', '${name}') -Split '\n') | ForEach-Object { pip install --upgrade $_ }