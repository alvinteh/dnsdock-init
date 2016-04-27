dnsdock-init
=========

A simple utility that allows for quick setup of DNSDock: from creating and starting a Docker machine to adding the routes to starting the DNSDock container, everything is done automatically.

Usage
-------
Simply run `source init.sh`, and use Docker and/or DNSDock in your Dockerfiles/Docker Compose files from there.

The DNS TLD has been set to ".docker" but can be easily changed.

License
-------
Copyright 2016 Alvin Teh.
Licensed under the MIT license.
