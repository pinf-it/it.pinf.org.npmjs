#!/usr/bin/env bash.origin.script

depend {
    "npm": {
        "@com.github/pinf-it/it.pinf.org.npmjs#s1": {
            "dependencies": {
                "require.async": "^0.1.1"
            }
        }
    }
}

echo "TEST_MATCH_IGNORE>>>"
pushd "$__DIRNAME__" > /dev/null
    CALL_npm ensure dependencies
popd > /dev/null
echo "<<<TEST_MATCH_IGNORE"


if [ ! -e ".rt/it.pinf.org.npmjs/node_modules/require.async/require.async.js" ]; then
    echo "ERROR: not installed!"
    exit 1
fi

echo "OK"
