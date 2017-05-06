#!/usr/bin/env bash.origin.script

function PRIVATE_ensure {

    if [ "$1" == "dependencies" ]; then

        local baseDir="$(pwd)/.rt/it.pinf.org.npmjs"

        local modulesDir="${baseDir}/node_modules"

        # TODO: Only install if checksum of descriptor has changes as compared to '.installed'
        #       as well as install context.

        if [ ! -e "$modulesDir" ]; then
            mkdir -p "$baseDir" > /dev/null || true
        fi

        pushd "$baseDir" > /dev/null
            BO_run_node --eval '
                const FS = require("fs");

                const setName = process.argv[1];
                const declarations = JSON.parse(process.argv[2]);

                if (!declarations[setName]) {
                    console.error("ERROR: Set name \"" + setName + "\" not found!");
                    process.exit(1);
                }

                function deepObjectExtend (target, source) {
                    for (var prop in source) {
                        if (source.hasOwnProperty(prop)) {
                            if (target[prop] && typeof source[prop] === "object") {
                                deepObjectExtend(target[prop], source[prop]);
                            }
                            else {
                                target[prop] = source[prop];
                            }
                        }
                    }
                    return target;
                }

                var descriptor = {};
                if (FS.existsSync("package.json")) {
                    descriptor = JSON.parse(FS.readFileSync("package.json", "utf8"));
                }
                // TODO: Instead of pummeling existing versions use the highest one.
                descriptor[setName] = deepObjectExtend(descriptor[setName] || {}, declarations[setName]);

                // TODO: If no version specified for name use latest version.

                FS.writeFileSync("package.json", JSON.stringify(descriptor, null, 4), "utf8");
            ' "$1" "$__ARG1__"

            # TODO: Checksum descriptor and write '.installed' file
            BO_run_npm install

        popd > /dev/null

    else
        echo "ERROR: Unknown set name '$1'"
        exit 1
    fi
}


echo "TEST_MATCH_IGNORE>>>"
pushd "$__CALLER_DIRNAME__" > /dev/null
    PRIVATE_ensure dependencies
popd > /dev/null
echo "<<<TEST_MATCH_IGNORE"
