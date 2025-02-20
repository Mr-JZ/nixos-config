{ pkgs }:

pkgs.writeShellScriptBin "42-make-local" ''
  # Function to replace a line in a file
  replace_line() {
    file="$1"
    old_line="$2"
    new_line="$3"

    if [[ ! -f "$file" ]]; then
      echo "Error: File '$file' not found."
      return 1
    fi

    if ! grep -q "$old_line" "$file"; then
        echo "Warning: Line '$old_line' not found in '$file'."
        return 0 # Not an error, just a warning
    fi

    sed -i "s/$old_line/$new_line/" "$file"
    echo "Replaced line in '$file'."
    return 0
  }

  # --- app.module.ts changes ---
  app_module_file="app.module.ts"

  # MongoDB connection string change
  old_mongo_line="MongooseModule.forRoot(process.env.MONGODB_CONNECTION_STRING || 'mongodb://127.0.0.1/local')"
  new_mongo_line="MongooseModule.forRoot(process.env.MONGODB_CONNECTION_STRING || 'mongodb://cbam-facilitator_development:A8q3Do9Gf93osdaEjR8Fegns5UwA7M@traefik.sustainaccount.de/cbam-facilitator_development?authMechanism=DEFAULT&authSource=cbam-facilitator_development')"

  replace_line "$app_module_file" "$old_mongo_line" "$new_mongo_line"

  # --- backend-core/package.json changes ---
  package_json_file="backend-core/package.json"

  # Start script change
  old_start_line='"start": "set DEV=true && nest start --watch"'
  new_start_line='"start": "export DEV=true && nest start --watch"'

  replace_line "$package_json_file" "$old_start_line" "$new_start_line"

  # Start-local script addition
  new_start_local_line='"start-local": "export DEV=true; docker run --name mongodb --rm -p 27017:27017 mongo:latest > /dev/null & nest start --watch"'

  # Check if start-local exists, if not add it
  if ! grep -q '"start-local":' "$package_json_file"; then
    sed -i "/'start':/a\\    $new_start_local_line," "$package_json_file"
    echo "Added start-local script to package.json"
  fi
''
