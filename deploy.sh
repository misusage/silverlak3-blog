#!/bin/bash

#------------
#Setup the public folder to work with the github io repo first! Why?
#Github pages works off of the <USERNAME>.github.io repo. This is what gets rendered as a website. This script and all the source code content lives in a separate repo.
#The command below creates a git submodule. Now when you run the hugo command to build your site to public, the created public directory will have a different remote origin (i.e. hosted GitHub.io repository).
#git submodule add -b master git@github.com:<USERNAME>/<USERNAME>.github.io.git public
#Then, all you have to do is run this script everytime you want to update the website. Once hugo finishes compiling, this script will upload only the compiled content over to the github.io page.
#------------

#If you want a custom commit message, add it as an argument to this script, deploy.sh "<commit message>"
echo "-------------------------------"
echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
echo "-------------------------------"

# Clean the published dir
#if [ -d "public/.git" ]; then
#  echo "-------------------------------"
#  echo -e "\033[0;32mDeleting published directory...\033[0m"
#  echo "-------------------------------"
#	/bin/rm -rf public/* # Keeps the .git
#fi

# Build the project.
echo "-------------------------------"
echo -e "\033[0;32mCompiling site...\033[0m"
echo "-------------------------------"
hugo -t hugo-tranquilpeak-theme # if using a theme, replace with `hugo -t <YOURTHEME>`

if [ ! -f "public/.git" ]; then
  echo "-------------------------------"
  echo -e "\033[0;32mAdding public as a submodule...\033[0m"
  echo "-------------------------------"
  git submodule add -b master git@github.com:silverlak3/silverlak3.github.io.git public
fi

# Go To Public folder
cd public
# Add changes to git.
git add .

# Commit changes.
msg="Updating Website `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
echo "-------------------------------"
echo -e "\033[0;32mCommiting with Message: $msg...\033[0m"
echo "-------------------------------"
git commit -m "$msg"

# Push source and build repos.
echo "-------------------------------"
echo -e "\033[0;32mPushing to Github...\033[0m"
echo "-------------------------------"
git push origin master

# Come Back up to the Project Root
cd ..
echo "-------------------------------"
echo -e "\033[0;32mDONE...\033[0m"
echo "-------------------------------"
