#!/usr/bin/env bash.origin.script

depend {
    "npm": {
        "@github.com/pinf-it/it.pinf.org.npmjs#s1": {
            "dependencies": {
                "require.async": "^0.1.1"
            }
        }
    }
}

if [ ! -e ".rt/it.pinf.org.npmjs/node_modules/require.async/require.async.js" ]; then
    echo "ERROR: not installed!"
    exit 1
fi

echo "OK"
