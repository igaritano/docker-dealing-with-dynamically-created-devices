#! /bin/bash

# Copyright (C) 2019 Iñaki Garitano.
#
# Author: Iñaki Garitano <igaritano@garitano.org>
# Version: 1.0
# Created: 2019.10.06
# Keywords: docker dynamic device
# URL: https://github.com/igaritano/docker-dealing-with-dynamically-created-devices
#
# This file is NOT part of GNU Emacs.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Comentary:
#
# This file creates or removes character, block or pipe type device paths
# or definitions from guest containers. This is necessary when devices
# such as usb stics are connected and disconnected dynamicaly.
#
# UDEV or userspace /dev, the Linux kernel device manager, is the
# responsable of calling this file when a new device is detected
# or an old one is removed. UDEV rules can be adjusted to control when
# this file is called. Thus, is possible to control if all possible
# devices or just a specific one have to be managed by this file.
#
# Note:
#
# In order to this work, the guest container must be launch with the
# following options:
#
# --device /dev/bus/usb
# --device-cgroup-rule='c 189:* rmw'
#
# and/or
#
# $(if [[ -n $(find /dev/hidraw* -type c) ]]; then for device in /dev/hidraw*; do echo -n "--device $device:$device "; done fi)
# --device-cgroup-rule='c 242:* rmw'
#
#
#
# This is an example of two UDEV rules:
#
# ACTION=="mknod", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", MODE="0666", \
    # RUN+="/usr/bin/dkr-usb-mknod-rm.sh operation container_user_type $major $minor $tempnode container_name"
#
#
# ACTION=="mknod", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", MODE="0666", \
    # RUN+="/usr/bin/dkr-usb-mknod-rm.sh mknod regular $major $minor $tempnode keepassxc"
# ACTION=="mknod", KERNEL=="hidraw*", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", MODE="0666", \
    # RUN+="/usr/bin/dkr-usb-mknod-rm.sh mknod regular $major $minor $tempnode firefox"
#
#ACTION=="rm", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", \
    # RUN+="/usr/bin/dkr-usb-mknod-rm.sh rm regular keepassxc firefox"
#

# Code

device_paths=('/dev/hidraw*' '/dev/bus/usb') # array for device paths
device_major_numbers=(247 189) # array of device major numbers
device_file_types=('c' 'b' 'p') # device file types
device_file_types_regex=('^c.*' '^b.*' '^p.*') # regular expressions for device file types
operations=('mknod' 'rm') # possible operations
container_users=('root' 'regular') # array of types of users inside the container
regex=('^[0-9]{1,3}$' '^/dev/hidraw.+$' '^/dev/bus/usb/.+$') # array of regular expressions

declare -a containers # array for containers to have into account


# This function mknods the newly connected device into the guest container only if major number and
# device path are valid
function mknod_device_to_container {
    for container in ${containers[@]}
    do
	# check if device major number belongs to the accepted list of device major numbers
	skip=
	for major_number in ${device_major_numbers[@]}
	do
	    [[ $device_major_number == $major_number ]] && { skip=1; break; }
	done

	# check device file type
	device_file=$(ls -l $device_path)
	for i in ${!device_file_types[@]}
	do
	    if [[ $device_file =~ ${device_file_types_regex[i]} ]]; then
		device_file_type=${device_file_types[i]}
	    fi
	done

	# either directly or call to a program inside container to create device file inside the container
	if [[ -n $device_file_type ]]; then
	    if [[ $container_user == 'root' ]]; then
		[[ -z $skip ]] || { $(docker exec $container bash -c '/bin/mknod '$device_path' '$device_file_type' '$device_major_number' '$device_minor_number); }
	    else
		[[ -z $skip ]] || { $(docker exec $container bash -c '/usr/bin/dkr-mknod-rm mknod '$device_path' '$device_file_type' '$device_major_number' '$device_minor_number); }
	    fi
	fi
    done
}

# This function compares devices connected to host and guest and rms those which are only
# present at guest
function rm_device_from_container {
    for container in ${containers[@]}
    do
	for device_path in ${device_paths[@]}
	do
	    devices_at_host=$(find $device_path ! -type d)
	    devices_at_guest=$(docker exec $container bash -c 'find '$device_path' ! -type d')
	    rm_devices=()
	    # For each device at guest container
	    for device_at_guest in ${devices_at_guest[@]}
	    do
		# Initialize an empty variable to null
		skip=
		# For each device at host system
		for device_at_host in ${devices_at_host[@]}
		do
		    # Compare both devices. If not the same set skip and break
		    [[ $device_at_guest == $device_at_host ]] && { skip=1; break; }
		done
		# If skip variable NULL, mknod device into rm_devices array
		[[ -n $skip ]] || rm_devices+=($device_at_guest)
	    done

	    # For each device at rm_devicesarray
	    for rm_device in ${rm_devices[@]}
	    do
		# Rm device from guest container
		if [[ $container_user == 'root' ]]; then
		    $(docker exec $container bash -c '/bin/rm '$rm_device)
		else
		    $(docker exec $container bash -c '/usr/bin/dkr-mknod-rm rm '$rm_device)
		fi
	    done
	done
    done
}

# check if there are more than one arguments and the first argument is either 'mknod' or 'rm'
if [[ $# -ge 1 && ($1 =~ ${operations[0]} || $1 =~ ${operations[1]}) ]]; then
    operation=$1

    # check if there are more than two arguments and the argument is either 'root' or 'regular'
    if [[ $# -ge 2 && ($2 =~ ${container_users[0]} || $2 =~ ${container_users[1]}) ]]; then
	container_user=$2

	case $operation in
	    'mknod')
		# chech if there are at least six  arguments, third and fourth arguments are numbers and fifth is a valid device path
		if [[ $# -gt 5 && $3 =~ ${regex[0]} && $4 =~ ${regex[0]} && ($5 =~ ${regex[1]} || $5 =~ ${regex[2]}) ]]; then
		    device_major_number=$3
		    device_minor_number=$4
		    device_path=$5
		    for i in $(seq 1 $#)
		    do
			if [ 5 -lt $i ]; then
			    containers+=(${!i})
			fi
		    done
		    mknod_device_to_container
		fi
		;;
	    'rm')
		for i in $(seq 1 $#)
		do
		    if [ 2 -lt $i ]; then
			containers+=(${!i})
		    fi
		done
		rm_device_from_container
		;;
	esac
    fi
fi
