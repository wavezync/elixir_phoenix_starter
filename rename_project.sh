#!/bin/bash

set -e

# Function to convert snake_case to CamelCase
snake_to_camel() {
    echo "$1" | perl -pe 's/(^|_)([a-z])/\U$2/g'
}

# Function to convert CamelCase to snake_case
camel_to_snake() {
    echo "$1" | perl -pe 's/([A-Z])/_\l$1/g' | perl -pe 's/^_//'
}

# Check if at least the app name is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <app_name> [module_name]"
    exit 1
fi

app_name="$1"
module_name="${2:-$(snake_to_camel "$app_name")}"

old_app_name="elixir_phoenix_starter"
old_module_name="ElixirPhoenixStarter"

# Define the directories to process
directories="lib priv test rel config"

# Rename directories
for dir in $directories; do
    find "$dir" -depth -type d -name "*${old_app_name}*" | while read -r d; do
        new_dir=$(echo "$d" | perl -pe "s/${old_app_name}/${app_name}/g")
        mv "$d" "$new_dir"
    done
done

# Rename files
for dir in $directories; do
    find "$dir" -type f \( -name "*${old_app_name}*" -o -name "*${old_module_name}*" \) | while read -r file; do
        new_file=$(echo "$file" | perl -pe "s/${old_app_name}/${app_name}/g")
        new_file=$(echo "$new_file" | perl -pe "s/${old_module_name}/${module_name}/g")
        mv "$file" "$new_file"
    done
done

# Function to process a file
process_file() {
    local file="$1"
    # Replace app name
    perl -i -pe "s/${old_app_name}/${app_name}/g" "$file"
    
    # Replace module name
    perl -i -pe "s/${old_module_name}/${module_name}/g" "$file"
    
    # Replace CamelCase variations
    old_camel=$(snake_to_camel "$old_app_name")
    new_camel=$(snake_to_camel "$app_name")
    perl -i -pe "s/${old_camel}/${new_camel}/g" "$file"
    
    # Replace snake_case variations
    old_snake=$(camel_to_snake "$old_module_name")
    new_snake=$(camel_to_snake "$module_name")
    perl -i -pe "s/${old_snake}/${new_snake}/g" "$file"
    
    # Replace module name in dot notation (e.g., ElixirPhoenixStarter.Something)
    perl -i -pe "s/${old_module_name}\./${module_name}./g" "$file"
    
    # Replace module name in __MODULE__ syntax
    perl -i -pe "s/__MODULE__\./${module_name}./g" "$file"
}

# Replace content in files
for dir in $directories; do
    find "$dir" -type f \( -name "*.ex" -o -name "*.exs" -o -name "*.eex" -o -name "*.leex" -o -name "*.heex" \) | while read -r file; do
        process_file "$file"
    done
done

# Process mix.exs separately
if [ -f "mix.exs" ]; then
    process_file "mix.exs"
    # Replace module name in mix.exs for application name
    perl -i -pe "s/app: :${old_app_name}/app: :${app_name}/g" "mix.exs"
fi

# Process README.md separately
if [ -f "README.md" ]; then
    process_file "README.md"
fi

echo "Renaming complete. App name changed to ${app_name} and module name changed to ${module_name}."

echo "Running mix phx.gen.release..."
mix phx.gen.release

echo "Running mix format..."
mix format