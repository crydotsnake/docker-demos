#!/bin/zsh
set -euo pipefail


# What is this update.sh?
# It's a helper script you run whenever you've updated the demo versions or modified the Docker setup.
# It generates all the Dockerfiles from templates and the post_push hooks containing image tags.
# Once you commit and push the changes, Docker Hub will trigger automated builds of new images.

# Usage:
# `./update.sh`
# As you can see in line 1, the script runs in zsh. This is the default shell in Mac OS since Catalina.
# You could run it in a bash shell as well (`#!/bin/bash`), but it requires at least bash 4.x to deal
# with associative arrays (hash tables). Check your version with `bash --version`.


# check requirements
command -v gsed >/dev/null 2>&1 || {
    echo >&2 "GNU sed is required. If you're on Mac OS, use 'brew install gnu-sed' to install.";
    exit 1;
}


# configuration ---------------------------------------------------------------

# declare commands and image bases for given variants
variants=( base community onepage )

# declare package versions
declare -A packageVersions=(
    [base]='2.8.0'
    [community]='3.1.1'
    [onepage]='1.4.0'
)

# -----------------------------------------------------------------------------

# loop through image variants
for variant in "${variants[@]}"; do

    # declare and make directory for given PHP version and image variant
    dir="$variant"
    mkdir -p "$dir"

    # declare tags for current version and variant
    tags=( "${variant}" )

    packageName="demo_${variant}"
    packageVersion="${packageVersions[$variant]}"

    # bring out debug infos
    echo "- Image: $variant - $packageName@$packageVersion"
    echo "  Tags:"
    printf "  - %s\n" ${tags}

    # copy hook from template, replace placeholders
    mkdir -p "$dir/hooks"
    gsed -r \
        -e 's!%%TAGS%%!'"$tags"'!g' \
        "templates/post_push.sh" > "$dir/hooks/post_push"

    # copy custom-setup file, replace placeholders
    gsed -r \
        -e 's!%%PACKAGE%%!'"$packageName"'!g' \
        -e 's!%%VERSION%%!'"$packageVersion"'!g' \
        "templates/custom-setup.sh" > "$dir/custom-setup.sh"
    chmod +x "$dir/custom-setup.sh"

    # copy remaining files
    cp "templates/Dockerfile" "$dir/Dockerfile"
    cp "templates/mysql.list" "$dir/mysql.list"
done