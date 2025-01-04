#!/bin/bash

# Define the file to store the output in /home/kade
LOG_FILE="/home/kade/TempCheck/cpu_temp_log.txt"

# Initialize an array to store the last 10 averages
declare -a averages
MAX_AVG_COUNT=10

# Function to get the current CPU temperature using vcgencmd
get_cpu_temp() {
    # Use vcgencmd to get the temperature in Celsius
    temp=$(vcgencmd measure_temp | grep -o '[0-9]*\.[0-9]*')
    echo "$temp"
}

# Function to calculate the average of the last 10 temperatures
calculate_average() {
    total=0
    count=0
    for temp in "${temp_array[@]}"; do
        total=$(echo "$total + $temp" | bc)
        count=$((count + 1))
    done
    if [ "$count" -gt 0 ]; then
        avg=$(echo "scale=2; $total / $count" | bc)
    else
        avg=0
    fi
    echo "$avg"
}

# Start the loop to check CPU temperature continuously
while true; do
    # Initialize the array and counter for 100 checks
    counter=0
    temp_array=()

    # Do 100 checks
    while [ "$counter" -lt 100 ]; do
        # Get the current temperature
        current_temp=$(get_cpu_temp)

        # Add the current temperature to the array
        temp_array+=("$current_temp")

        # If there are more than 10 values, remove the oldest one
        if [ "${#temp_array[@]}" -gt 10 ]; then
            temp_array=("${temp_array[@]:1}")
        fi

        # Increment the counter
        counter=$((counter + 1))

        # Wait 1 second before checking again
        sleep 1
    done

    # After 100 checks, calculate the average and add it to the list of averages
    average_temp=$(calculate_average)

    # Add the new average to the top of the list
    averages=("$average_temp" "${averages[@]}")

    # If there are more than 10 averages, remove the oldest one
    if [ "${#averages[@]}" -gt "$MAX_AVG_COUNT" ]; then
        averages=("${averages[@]:0:$MAX_AVG_COUNT}")
    fi

    # Get the current date and time
    current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

    # Clear the log file before appending new data
    > "$LOG_FILE"

    # Append the current time, separator, and averages list to the log file
    echo "Log Time: $current_datetime" >> "$LOG_FILE"
    echo "------------------------" >> "$LOG_FILE"
    echo "Current Temp: $current_temp°C, Last 10 Averages: ${averages[@]}" >> "$LOG_FILE"
done
