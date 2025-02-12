#!/bin/bash

# Function to add a tag for files with YAML front matter
add_tag_yaml() {
    awk '
    BEGIN { in_yaml = 0; tag_added = 0 }
    /^---/ {
        if (in_yaml == 1 && tag_added == 0) {
            print "tags:\n  - Blogger Archive"
            tag_added = 1
        }
        in_yaml = 1 - in_yaml
    }
    { print }
    ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# Function to add a tag for files with TOML front matter
add_tag_toml() {
    awk '
    BEGIN { in_toml = 0; tag_added = 0 }
    /^\+\+\+/ {
        if (in_toml == 1 && tag_added == 0) {
            print "tags = [\"Blogger Archive\"]"
            tag_added = 1
        }
        in_toml = 1 - in_toml
    }
    { print }
    ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# Function to add a tag for files with JSON front matter
add_tag_json() {
    awk '
    BEGIN { in_json = 0; bracket_count = 0; tag_added = 0 }
    {
        if ($0 ~ /\{/ ) bracket_count++
        if ($0 ~ /\}/ ) bracket_count--
        if (bracket_count == 0 && tag_added == 0) {
            print "  \"tags\": [\"Blogger Archive\"],"
            tag_added = 1
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
                add_tag_yaml "$file"
                ;;
            "+++")
                # TOML front matter
                echo "Processing TOML front matter for $file"
                add_tag_toml "$file"
                ;;
            "{")
                # JSON front matter
                echo "Processing JSON front matter for $file"
                add_tag_json "$file"
                ;;
            *)
                echo "Unrecognized front matter in $file"
                ;;
        esac
    fi
done

echo "Tags added successfully."
