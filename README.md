Time Stamping Server
====================

Implementation of a Time Stamping Authority HTTP server that can be used with `jarsigner` tool.

Start and expiration dates for generated certificates may be set to arbitrary values in `bin/setup.sh` script,
see `conf/openssl-*.conf` for other certificates details.

See [RFC 3161](https://www.ietf.org/rfc/rfc3161.txt) for the details about timestamping.

Usage
-----

Prerequisites: `openssl`, `faketime`.

    # create certificates
    ./bin/setup.sh

    # start server
    ./bin/server.sh

    # create and sign JAR
    javac Hello.java
    jar -cf hello.jar Hello.class
    jarsigner -keystore ./work/sign.p12 -storepass 1234 -keypass 1234 hello.jar "Test Signer" -tsa http://127.0.0.1:8080/
    jarsigner -keystore ./work/sign.p12 -storepass 1234 -keypass 1234 -verify hello.jar -verbose -certs

To sign JARs "in the past" use `faketime` for both jarsigner and TS server.

License information
-------------------

Scripts are released under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).