#!/bin/bash

# Script to list installed packages not from Debian origin and show their source repository
# Results are also saved to output file

output_file="non_debian_packages.txt"
echo "Listing installed packages not from Debian origin..." | tee "$output_file"
echo | tee -a "$output_file"

# Get the list of installed packages not from Debian origin
packages=$(apt list '?narrow(?installed, ?not(?origin(Debian)))' 2>/dev/null | grep -v Listing | cut -d/ -f1)

# Loop through each package and show its origin using apt-cache policy
for pkg in $packages; do
  echo "=== Package: $pkg ===" | tee -a "$output_file"
  apt-cache policy "$pkg" | grep -E 'Installed|500|http|https' | tee -a "$output_file"
  echo | tee -a "$output_file"
done
