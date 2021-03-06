###############################################################
#
# Purpose: Makefile for "M-JPEG Streamer"
# Author.: Tom Stoeveken (TST)
# Version: 0.4
# License: GPL
#
###############################################################

# specifies where to install the binaries after compilation
# to use another directory you can specify it with:
# $ sudo make DESTDIR=/some/path install
DESTDIR = /usr/local

# set the compiler to use
CC = gcc

SVNDEV := -D'SVN_REV="$(shell svnversion -c .)"'
CFLAGS += $(SVNDEV)

# general compile flags, enable all warnings to make compile more verbose
CFLAGS += -DLINUX -D_GNU_SOURCE -Wall 
CFLAGS += -g -Wuninitialized
#CFLAGS +=  -DDEBUG

# we are using the libraries "libpthread" and "libdl"
# libpthread is used to run several tasks (virtually) in parallel
# libdl is used to load the plugins (shared objects) at runtime
LFLAGS += -lpthread -ldl

# define the name of the program
APP_BINARY = mjpg_streamer

# define the names and targets of the plugins
PLUGINS = input_uvc.so
PLUGINS += output_file.so
PLUGINS += output_http.so
PLUGINS += input_raspicam.so

# define the names of object files
OBJECTS=mjpg_streamer.o utils.o

# this is the first target, thus it will be used implictely if no other target
# was given. It defines that it is dependent on the application target and
# the plugins
all: application plugins

application: $(APP_BINARY)

plugins: $(PLUGINS)

$(APP_BINARY): mjpg_streamer.c mjpg_streamer.h mjpg_streamer.o utils.c utils.h utils.o
	$(CC) $(CFLAGS) $(OBJECTS) $(LFLAGS) -o $(APP_BINARY)
	chmod 755 $(APP_BINARY)

ifeq ($(USE_LIBV4L2),true)
input_uvc.so: mjpg_streamer.h utils.h
	make -C plugins/input_uvc USE_LIBV4L2=true all
	cp plugins/input_uvc/input_uvc.so .
else
input_uvc.so: mjpg_streamer.h utils.h
	make -C plugins/input_uvc all
	cp plugins/input_uvc/input_uvc.so .
endif

output_file.so: mjpg_streamer.h utils.h
	make -C plugins/output_file all
	cp plugins/output_file/output_file.so .

output_http.so: mjpg_streamer.h utils.h
	make -C plugins/output_http all
	cp plugins/output_http/output_http.so .

input_raspicam.so: mjpg_streamer.h utils.h
	cd plugins/input_raspicam/build; cmake ..
	make -C plugins/input_raspicam/build
	cp plugins/input_raspicam/build/libinput_raspicam.so ./input_raspicam.so

# cleanup
clean:
	make -C plugins/input_uvc $@
	make -C plugins/output_file $@
	make -C plugins/output_http $@
	rm -f *.a *.o $(APP_BINARY) core *~ *.so *.lo
	rm -f -r plugins/input_raspicam/build/*
	echo "This folder is where the plugin gets built" > plugins/input_raspicam/build/Readme.md

# useful to make a backup "make tgz"
tgz: clean
	mkdir -p backups
	tar czvf ./backups/mjpg_streamer_`date +"%Y_%m_%d_%H.%M.%S"`.tgz --exclude backups --exclude .svn *

# install MJPG-streamer and example webpages
install: all
	install --mode=755 $(APP_BINARY) $(DESTDIR)/bin
	install --mode=644 $(PLUGINS) $(DESTDIR)/lib/
	install --mode=755 -d $(DESTDIR)/www
	install --mode=644 -D www/* $(DESTDIR)/www

# remove the files installed above
uninstall:
	rm -f $(DESTDIR)/bin/$(APP_BINARY)
	for plug in $(PLUGINS); do \
	  rm -f $(DESTDIR)/lib/$$plug; \
	done;
