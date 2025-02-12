#!/bin/bash

# Check if a categories argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <new-categories>"
    exit 1
fi

NEW_categories="$1"

# Function to update categories for files with YAML front matter
update_categories_yaml() {
    awk -v new_categories="$NEW_categories" '
    BEGIN { in_yaml = 0; categories_updated = 0 }
    /^---/ {
        if (in_yaml == 1) {
            if (categories_updated == 0) {
                print "categories: " new_categories
                categories_updated = 1
            }
        }
        in_yaml = 1 - in_yaml
    }
    /^categories: / {
        if (in_yaml == 1 && categories_updated == 0) {
            print "categories: " new_categories
            categories_updated = 1
            next
        }
    }
    { print }
    ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# Function to update categories for files with TOML front matter
update_categories_toml() {
    awk -v new_categories="$NEW_categories" '
    BEGIN { in_toml = 0; categories_updated = 0 }
    /^\+\+\+/ {
        if (in_toml == 1) {
            if (categories_updated == 0) {
                print "categories = \"" new_categories "\""
                categories_updated = 1
            }
        }
        in_toml = 1 - in_toml
    }
    /^categories = / {
        if (in_toml == 1 && categories_updated == 0) {
            print "categories = \"" new_categories "\""
            categories_updated = 1
            next
        }
    }
    { print }
    ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# Function to update categories for files with JSON front matter
update_categories_json() {
    awk -v new_categories="$NEW_categories" '
    BEGIN { in_json = 0; bracket_count = 0; categories_updated = 0 }
    {
        if ($0 ~ /\{/ ) bracket_count++
        if ($0 ~ /\}/ ) bracket_count--
        if ($0 ~ /"categories":/ && bracket_count > 0 && categories_updated == 0) {
            print "  \"categories\": \"" new_categories "\","
            categories_updated = 1
            next
        }
        if (bracket_count == 0 && categories_updated == 0) {
            print "  \"categories\": \"" new_categories "\","
            categories_updated = 1
        }
        print
    }
    ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# Loop through all .md files in the current directory
for file in *.md; do
    if [[ -f "$file" ]]; then
        content=$(head -n 1 "$file")
        case "$content" in
            "---")
                # YAML front matter
                echo "Processing YAML front matter for $file"
                update_categories_yaml "$file"
                ;;
            "+++")
                # TOML front matter
                echo "Processing TOML front matter for $file"
                update_categories_toml "$file"
                ;;
            "{")
                # JSON front matter
                echo "Processing JSON front matter for $file"
                update_categories_json "$file"
                ;;
            *)
                echo "Unrecognized front matter in $file"
                ;;
        esac
    fi
done

echo "categories updated successfully to '$NEW_categories'."
