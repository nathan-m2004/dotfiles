#!/bin/bash

# Script: check_yay_updates.sh
# Purpose: Counts and returns the number of outdated AUR packages using 'yay'.

# 1. Run 'yay -Qu' to list outdated packages.
#    -Q: Query mode
#    -u: Outdated packages
# 2. Pipe the output to 'wc -l' (word count, lines) to get the count.
# 3. Redirect stderr (2>) to /dev/null to suppress error/warning messages from yay 
#    during the check, ensuring only the final count is outputted.

# Capture the number of outdated packages
OUTDATED_PACKAGES=$(yay -Qu 2> /dev/null | wc -l)
YAY_STATUS=$?

# Check the exit status of the yay command.
# yay returns 0 if updates are found, 1 if no updates are found, and 127 if not installed.
if [ $YAY_STATUS -eq 127 ]; then
    # Command not found, likely 'yay' is not installed.
    echo "Error: 'yay' command not found. Please ensure the AUR helper is installed." >&2
    # In case of an error, we return 0 for the count.
    OUTDATED_PACKAGES=0 
elif [ $YAY_STATUS -ne 0 ] && [ $YAY_STATUS -ne 1 ]; then
    # General failure (e.g., network issue, configuration error)
    echo "Warning: 'yay -Qu' failed with exit status $YAY_STATUS. Check your configuration." >&2
    OUTDATED_PACKAGES=0
fi

# Print the final count of outdated packages.
echo "$OUTDATED_PACKAGES"

# Exit with status 0 to indicate the script executed successfully (the check worked).
exit 0
