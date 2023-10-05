set ignore-comments := true

# Install python package dependencies.
install-deps:
  python3 -m pip install -r requirements.txt

# Remove all rendered templates and ignition files (excluding secrets.yml).
clean:
  git clean -x -d -f -e secrets.yml

# Renders jinja templates to produce butane configurations
configure: clean
  #!/usr/bin/env bash
  shopt -s globstar
  for file in **/*.j2; do ./render_template.py ${file#templates/} "secrets.yml"; done

# Transpiles butane configurations to create an ignition file
build:
  #!/usr/bin/env bash
  just install-deps
  test -f config.bu || just configure
  
  # Build dependent configurations
  shopt -s globstar
  for file in **/*.bu; do
    if [ "$file" != "config.bu" ]; then
      output_file="${file%.bu}.ign"
      butane -p -d . -o "$output_file" "$file"
    fi
  done

  # Build primary configuration
  butane -p -d . -o config.ign config.bu

# Hosts the ignition file for deployment
serve:
  test -f config.ign || just build
  python3 -m http.server
