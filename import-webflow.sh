#!/bin/bash

# Clean up the directories and files
rm -rf templates
rm -rf products/passport*
rm -rf products/identity*
rm *old*

IFS=$(echo -en "\n\b")
for file in images/*; do
  if ! grep -r -- "${file}" * > /dev/null; then
    echo "Removing ${file}"
    rm ${file}
  fi
done

# Remove the .html extensions (except for full qualified URLs)
for file in $(find . -name '*.html'); do
  cat ${file} | \
    sed 's/href="\([^h"]*\)\.html"/href="\1"/g' | \
    sed 's/href="\(.*\)\/index"/href="\1"/g' | \
    sed 's/href="\(.*\)\/_index"/href="\1"/g' | \
    sed 's/href="index"/href="\/"/g' > temp.html
  rm ${file}

  # Move and rename _index files to index
  mv temp.html ${file/_index/index}
done
