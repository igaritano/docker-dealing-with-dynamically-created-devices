#!/bin/bash

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
#
# Comentary:
#
# This file creates or removes character, block or pipe type device paths
# or definitions.
# It is necessary when running a container with a regular user.
# This file is placed inside each container and is executed
# by a C program inside the container.
#
# Code

if [[ "mknod" = $1 ]]
then
    /bin/su -c "/bin/mknod -m 0666 $2 $3 $4 $5" -
elif [[ "rm" = $1 ]]
then
    /bin/su -c "/bin/rm -rf $2" -
fi
