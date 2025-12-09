#!/bin/bash

# This script will run indefinitely, waiting for 30 minutes
# between each successful iteration.

while true
do
  echo "Script ran successfully at $(date). Exiting with code 0..."
  
  # The `exit 0` command is not actually reached here.
  # The script remains in a state of success because it doesn't fail.
  # The script process itself is what is running.
  
  # Wait for 30 minutes (1800 seconds)
  sleep 1800
done

# The script itself never fails, so its return code is always 0.
exit 0