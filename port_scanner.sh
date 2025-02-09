#!/bin/bash

echo "Enter the target IP address:"
read target

# Ask for the maximum number of simultaneous processes
echo "Enter the maximum number of simultaneous scans (e.g., 50):"
read max_procs

echo "Scanning all ports (1-65535) on $target..."

# Initialize process counter
current_procs=0

# Loop through all 65535 ports
for (( port=1; port<=65535; port++ )); do
    (
        # Try to connect to the port using netcat (nc)
        nc -zv -w 1 $target $port 2>/dev/null
        if [ $? -eq 0 ]; then
            # Display the port when open
            echo "Port $port is open"

            # Attempt to grab a banner or service info using nc
            service_info=$(nc -v -w 3 $target $port < /dev/null 2>&1)

            # Debugging output to see raw nc response
            echo "Raw response for port $port: $service_info"

            # Improved banner and service detection with regex matching
            if echo "$service_info" | grep -E -i "(banner|SSH|http|FTP|telnet|SMTP|open|service)"; then
                echo "Service Info: $service_info"
            else
                echo "No service info available for port $port"
            fi
        fi
    ) &

    # Increment the process counter
    ((current_procs++))

    # If we reach the max number of simultaneous processes, wait for them to finish
    if ((current_procs >= max_procs)); then
        wait -n
        ((current_procs--))
    fi
done

# Wait for any remaining background processes to finish
wait
echo "Scan complete!"
