#!/bin/bash

# Clean the published dir
if [ -d "public/.git" ]; then
  echo -e "\033[0;32mDeleting published directory...\033[0m"
	/bin/rm -rf public/* # Keeps the .git
fi

# Build the project.
echo -e "\033[0;32mCompiling site...\033[0m"
hugo -t hugo-tranquilpeak-theme # if using a theme, replace with `hugo -t <YOURTHEME>`

echo "DONE."
