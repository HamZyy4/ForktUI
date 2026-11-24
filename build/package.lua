-- Generated from package.json | build/build.sh

return [[
{
    "name": "forktui",
    "version": "1.6.66-forktui.2",
    "main": "./dist/main.lua",
    "repository": "https://github.com/HamZyy4/ForktUI",
    "author": "sukitovone",
    "description": "A modular, responsive graphite interface toolkit for Roblox client experiences, maintained by sukitovone.",
    "license": "MIT",
    "scripts": {
        "dev": "bash build/build.sh dev $INPUT_FILE",
        "build": "bash build/build.sh build $INPUT_FILE",
        "live": "python3 -m http.server 8642",
        "watch": "chokidar . -i 'node_modules' -i 'dist' -i 'build' -c 'npm run dev --'",
        "live-build": "concurrently \"npm run live\" \"npm run watch --\"",
        "example-live-build": "INPUT_FILE=examples/full-example.client.lua npm run live-build"
    },
    "keywords": [
        "roblox",
        "luau",
        "ui-library",
        "interface",
        "components",
        "themeable"
    ],
    "devDependencies": {
        "chokidar-cli": "^3.0.0",
        "concurrently": "^9.2.0"
    },
    "homepage": "https://github.com/HamZyy4/ForktUI#readme"
}
]]
