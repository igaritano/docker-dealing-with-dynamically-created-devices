// Copyright (C) 2019 Iñaki Garitano.
//
// Author: Iñaki Garitano <igaritano@garitano.org>
// Version: 1.0
// Created: 2019.10.06
// Keywords: docker dynamic device
// URL: https://github.com/igaritano/docker-dealing-with-dynamically-created-devices
//
// This file is NOT part of GNU Emacs.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// Comentary:
//
// This file executes a script in order to create or remove character,
// block or pipe type device paths or definitions.
// It is necessary when running a container with a regular user.
// This file is placed inside each container and is called
// by a script in a host.
//
// Code

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char **argv)
{
  
    char *scriptname = "/usr/bin/dkr-mknod-rm.sh";
    int scriptlen = strlen(scriptname);
    int i = 1;

    // evaluate the length of arguments
    for ( i = 1; i < argc; i++)
      {
	scriptlen += 1; // space character
	scriptlen += strlen(argv[i]); // length of each argument
      }
    
    char *script = malloc(scriptlen); // allocate a string
    
    strcat(script, scriptname); // add script path into the string

    // add to the string each argument and a space between them
    for ( i = 1; i < argc; i++)
      {
        strcat(script, " ");
	strcat(script, argv[i]);
      }

    // run the script as root
    setuid( 0 );
    system( script );

    return 0;
}
