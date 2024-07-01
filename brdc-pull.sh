#!/bin/bash

# FTP server details
FTP_SERVER="gssc.esa.int"
FTP_PATH="gnss/data/daily/2024/brdc"

# Temporary file to store the list of files
TEMP_FILE=$(mktemp)

# ASCII art for messages
function ascii_message() {
    echo -ne "\r====================================\n"
    echo -ne "$1\n"
    echo -ne "====================================\n"
}

# Function to print messages on the same line
function print_message() {
    echo -ne "\r$1"
}

# Function to get the latest file
get_latest_file() {
    ascii_message "Connecting to FTP server..."

    # Suppress the FTP login messages
    stty -echo
    ftp -n $FTP_SERVER <<END_SCRIPT | grep -E "brdc[0-9]{4}\.24n\.gz" > $TEMP_FILE
quote USER anonymous
quote PASS
cd $FTP_PATH
ls
bye
END_SCRIPT
    stty echo

    ascii_message "Logged in successfully."

    # Extract the latest file based on the highest number and latest date
    latest_file=$(awk '{print $9}' $TEMP_FILE | sort -t'.' -k1.5,1.8n | tail -n 1)

    # Download the latest file
    if [[ -n "$latest_file" ]]; then
        ascii_message "Downloading the latest file..."
        wget -q ftp://$FTP_SERVER/$FTP_PATH/$latest_file -O $latest_file
        ascii_message "Download complete."

        # Extract the downloaded .gz file
        ascii_message "Extracting the file..."
        gunzip $latest_file
        ascii_message "Extraction complete: ${latest_file%.gz}           "
    else
        ascii_message "No matching files found.             "
    fi

    # Clean up
    rm -f $TEMP_FILE
}

# Call the function to get the latest file
get_latest_file
echo ""
