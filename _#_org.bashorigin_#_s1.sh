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

            if [ ! -e ".installed.log" ] || ! grep -q "$__ARG1__" ".installed.log"; then

                echo "TEST_MATCH_IGNORE>>>"

                BO_run_recent_node --eval '
                    // TODO: Relocate to "sourcemint"

                    const LIB = require("bash.origin.workspace").LIB;
                    const PATH = require("path");
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

                    if (process.env.BO_VERBOSE) {
                        console.error("[github.com~pinf-it~it.pinf.org.npmjs] descriptor:", descriptor);
                    }

                    // Now check if we can find all dependencies without installing
                    if (descriptor.dependencies) {
                        if (!FS.existsSync("node_modules")) {
                            FS.mkdirSync("node_modules");
                        }
                        Object.keys(descriptor.dependencies).forEach(function (name) {
                            var path = null;
                            try {
                                path = require.resolve(name + "/package.json");
                                console.log("Symlinking " + PATH.dirname(path) + " to " + (process.cwd() + "/node_modules/" + name));
                                FS.symlinkSync(PATH.dirname(path), "node_modules/" + name);
                                delete descriptor.dependencies[name];
                            } catch (err) {
                                try {
                                    path = LIB.resolve(name + "/package.json");
                                    console.error("Symlinking " + PATH.dirname(path) + " to " + (process.cwd() + "/node_modules/" + name));
                                    FS.symlinkSync(PATH.dirname(path), "node_modules/" + name);
                                    delete descriptor.dependencies[name];
                                } catch (err) {
                                    path = null;
                                }
                            }
                            var binCommands = {};
                            if (path) {
                                // See if we need to symlink a bin command
                                var subDesc = JSON.parse(FS.readFileSync(path, "utf8"));
                                if (subDesc.bin) {
                                    Object.keys(subDesc.bin).forEach(function (name) {
                                        binCommands[name] = PATH.join(path, "../../.bin", name);
                                    });
                                }
                            }
                            if (Object.keys(binCommands).length > 0) {
                                // Link bin commands
                                if (!FS.existsSync("node_modules/.bin")) {
                                    FS.mkdirSync("node_modules/.bin");
                                }
                                Object.keys(binCommands).forEach(function (name) {
                                    console.error("Symlinking " + binCommands[name] + " to " + (process.cwd() + "/node_modules/.bin/" + name));
                                    FS.symlinkSync(binCommands[name], "node_modules/.bin/" + name);                                
                                });
                            }
                        });
                    }
                    if (Object.keys(descriptor.dependencies).length === 0) {
                        console.error("All symlinked. No need to install:", process.cwd());
                        // No need to install.
                        if (FS.existsSync("package.json")) {
                            FS.unlinkSync("package.json");
                        }
                    } else {
                        FS.writeFileSync("package.json", JSON.stringify(descriptor, null, 4), "utf8");
                    }
                ' "$1" "$__ARG1__"


                rm -f package-lock.json || true

                function installError {
                    echo "ERROR while installing package '$(pwd)' using 'BO_run_npm install'!"
                    exit 1
                }

                if [ -e "package.json" ]; then

                    # TODO: Checksum descriptor and write '.installed' file
                    # TODO: Suppress WARN messages
                    if BO_has "npm"; then
                        npm install --production || installError
                    else
                        BO_run_npm install --production || installError
                    fi
                fi

                echo "<<<TEST_MATCH_IGNORE"

                echo "$__ARG1__" >> ".installed.log"
            fi

        popd > /dev/null

    else
        echo "ERROR: Unknown set name '$1'"
        exit 1
    fi
}


pushd "$__CALLER_DIRNAME__" > /dev/null
    PRIVATE_ensure dependencies
popd > /dev/null
