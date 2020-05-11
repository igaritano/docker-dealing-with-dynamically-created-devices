# docker-dealing-with-dynamically-created-devices

Docker - Dealing with dynamically created devices

This project deals with dynamically created devices and docker containers. The main objective is to connect and disconnect character devices, such as USB devices, into running docker containers. It has been tested only on GNU/Linux Debian and with a Yubikey. However, it should work on other GNU/Linux distributions and other character devices.
Depending on the configuration (UDEV rules), the project scripts deal with a specific device or a kind of devices, such as all USB devices.

Requirements
- Privileged access, root, within the host device
- Docker
- UDEV
- C compiler in case a regular user is used within docker container

Suggested setup steps (considering the host OS uses systemd as init program)
1.- Place dkr-dev-mknod-rm.sh, dkr-vboxdrv.sh script into /usr/bin folder
2.- Add execution flag to /usr/bin/dkr-dev-mknod-rm.sh and dkr-vboxdrv.sh scripts
3.- If the control of a specific device is needed
3.1.- Get device Vendor ID and Product ID (in case of Yubikey 4 idVendor=="1050" and idProduct=="0407")
      - # journalctl -f
	  - Connect the device and pay attention into the log messages
4.- Modify UDEV rule variables. Pay attention to idVender and idProduct if they are needed, and docker container name, such as keepassxc
5.- In case a regular user is used within the docker container
5.1.- Compile dkr-mknod-rm.c program
5.2.- Place compiled dkr-mknod-rm and dkr-mknod-rm.sh next to the Dockerfile
5.3.- Add the following lines into the Dockerfile
COPY /dkr-mknod-rm /usr/bin/dkr-mknod-rm
COPY /dkr-mknod-rm.sh /usr/bin/dkr-mknod-rm.sh

RUN chmod +x /usr/bin/dkr-mknod-rm \
 && chmod +x /usr/bin/dkr-mknod-rm.sh \
 && chmod u+s /usr/bin/dkr-mknod-rm
5.4.- Create a new docker image
