#!/usr/bin/env bash.origin.script

function EXPORTS_ensure {

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

                const declarations='$__ARG1__';
                const setName="'$1'";

                if (!declarations[setName]) {
                    console.error("ERROR: Set name \"" + setName + "\" not found!");
                    process.exit(1);
                }

                function deepMerge(a, b) {
                    // If neither is an object, return one of them:
                    if (Object(a) !== a && Object(b) !== b) return b || a;
                    // Replace remaining primitive by empty object/array
                    if (Object(a) !== a) a = Array.isArray(b) ? [] : {};
                    if (Object(b) !== b) b = Array.isArray(a) ? [] : {};
                    // Treat arrays differently:
                    if (Array.isArray(a) && Array.isArray(b)) {
                        // Merging arrays is interpreted as concatenation of their deep clones:
                        return [...a.map(v => deepMerge(v)), ...b.map(v => deepMerge(v))];
                    } else {
                        // Get the keys that exist in either object
                        var keys = new Set([...Object.keys(a),...Object.keys(b)]);
                        // Recurse and assign to new object
                        return Object.assign({}, ...Array.from(keys,
                            key => ({ [key]: deepMerge(a[key], b[key]) }) ));
                    }
                }

                var descriptor = {};
                if (FS.existsSync("package.json")) {
                    descriptor = JSON.parse(FS.readFileSync("package.json", "utf8"));
                }
                // TODO: Instead of pummeling existing versions use the highest one.
                descriptor[setName] = deepMerge(descriptor[setName] || {}, declarations[setName]);

                // TODO: If no version specified for name use latest version.

                FS.writeFileSync("package.json", JSON.stringify(descriptor, null, 4), "utf8");
            '

            # TODO: Checksum descriptor and write '.installed' file
            BO_run_npm install

        popd > /dev/null

    else
        echo "ERROR: Unknown set name '$1'"
        exit 1
    fi
}
