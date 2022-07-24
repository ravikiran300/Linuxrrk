
#!/bin/bash

# List items in a dir, filtering out the entries that show up in /proc/mounts
get_dir_items() {
        local path=$1

        ls -1d ${path}* | while read i; do
                if awk '{ print $2 }' /proc/mounts | grep -q "^${i}\$"; then
                        if [[ $flag -eq 0 ]] || [[ "$path" == "/" ]]; then
                                continue
                        fi
                fi
                echo $i
        done
}

# Find and display directories that contain at least 5GB
find_disk_usage() {
        local path=$1
        shift

        du -hsx "$@" $(get_dir_items ${path}) 2>/dev/null | grep -E '^[0-9]+(\.[0-9])?[GTP]' | grep -vE '^[0-4](\.[0-9])?G' | while read line; do
                dir=$(echo "$line" | awk '{ print $2 }')
                if [[ -d $dir ]]; then
                        echo "$line"
                        find_disk_usage "${dir}/"
                fi
        done
}

# Getting the Mount points from Nagios Alert Message.
get_mount_partitions() {
        local data=$1
        local IFS=$'\n'; data=($data)
        mountpoint_list=()
        for line in "${data[@]}"; do
                if [[ $line == "CRITICAL - free space:"* ]] || [[ $line == "WARNING - free space:"* ]]; then
                        temp=$(echo $line| cut -d' ' -f 5)
                        mount_point=$(echo $temp| sed -e 's/(RO)//g')
                        mountpoint_list+=($mount_point)
                fi
        done
}
