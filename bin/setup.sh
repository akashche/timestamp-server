#!/bin/bash

set -e
#set -x

CA_START_DATE=20150101000000Z
CA_END_DATE=20250101000000Z
SIGN_START_DATE=20160101000000Z
SIGN_END_DATE=20170101000000Z
TSA_CA_START_DATE=20160101000000Z
TSA_CA_END_DATE=20230101000000Z
TSA_START_DATE=20160101000000Z
TSA_END_DATE=20230101000000Z
KEYSTORE_DATE="2016-06-01 00:00:00"

BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVER_DIR="$BIN_DIR"/..

rm -rf "$SERVER_DIR"/work
mkdir "$SERVER_DIR"/work
pushd "$SERVER_DIR"/work > /dev/null

# CA directories
mkdir ./CA
mkdir ./CA/certs
mkdir ./CA/db
mkdir ./CA/private
touch ./CA/db/index
echo 01 > ./CA/db/serial

# CA request
openssl req -new -config "$SERVER_DIR"/conf/openssl-sign.conf -out rootca.csr -keyout ./CA/private/rootca.key -passout pass:1234

# sign CA
openssl ca -selfsign -config "$SERVER_DIR"/conf/openssl-sign.conf -in rootca.csr -out ./CA/rootca.pem -extensions ca_ext -startdate $CA_START_DATE -enddate $CA_END_DATE -passin pass:1234 -batch

# bare CA
openssl x509 -in ./CA/rootca.pem -outform PEM -out ./CA/rootca-bare.pem

# DER CA
openssl x509 -in ./CA/rootca.pem -outform DER -out ./CA/rootca.der

# CS request
openssl req -new -newkey rsa:2048 -subj "/C=US/O=Test Inc./OU=Engineering/CN=Test Signer" -keyout sign.key -out sign.csr -passout pass:1234

# sign CS
openssl ca -config "$SERVER_DIR"/conf/openssl-sign.conf -in sign.csr -out sign.pem -extensions sign_ext -startdate $SIGN_START_DATE -enddate $SIGN_END_DATE -passin pass:1234 -batch

# create keystore
faketime "$KEYSTORE_DATE" openssl pkcs12 -export -in sign.pem -inkey sign.key -out sign.p12 -name "Test Signer" -caname "Test Root CA" -chain -CAfile ./CA/rootca.pem -passin pass:1234 -passout pass:1234

# add CA to keystore
keytool -importcert -file ./CA/rootca.der -keystore sign.p12 -alias "Test Root CA" -storepass 1234 -storetype pkcs12 -noprompt

# TSA directories
mkdir ./TSA
mkdir ./TSA/certs
mkdir ./TSA/db
mkdir ./TSA/private
touch ./TSA/db/index
echo 01 > ./TSA/db/serial
echo 01 > ./TSA/tsa_serial

# TSA CA request
openssl req -new -config "$SERVER_DIR"/conf/openssl-ts.conf -out tsaca.csr -keyout ./TSA/private/tsaca.key -passout pass:1234

# sign TSA CA
openssl ca -config "$SERVER_DIR"/conf/openssl-sign.conf -in tsaca.csr -out ./TSA/tsaca.pem -extensions ca_ext -startdate $TSA_CA_START_DATE -enddate $TSA_CA_END_DATE -passin pass:1234 -batch

# bare TSA CA
openssl x509 -in ./TSA/tsaca.pem -outform PEM -out ./TSA/tsaca-bare.pem

# DER TSA CA
openssl x509 -in ./TSA/tsaca.pem -outform DER -out ./TSA/tsaca.der

# add TSA CA to keystore
#keytool -importcert -file ./TSA/tsaca.der -keystore sign.p12 -alias "Test TSA CA" -storepass 1234 -storetype pkcs12 -noprompt

# TSA request
openssl req -new -newkey rsa:2048 -subj "/C=US/O=Test Inc./OU=Engineering/CN=Test TSA" -keyout ./TSA/private/tsa.key -out tsa.csr -passout pass:1234

# sign TSA
openssl ca -config "$SERVER_DIR"/conf/openssl-ts.conf -in tsa.csr -out ./TSA/tsa.pem -extensions tsa_ext -startdate $TSA_START_DATE -enddate $TSA_END_DATE -passin pass:1234 -batch

# bare TSA
openssl x509 -in ./TSA/tsa.pem -outform PEM -out ./TSA/tsa-bare.pem

# TSA chain
cat ./TSA/tsa.pem ./TSA/tsaca-bare.pem > ./TSA/tsa-chain.pem

popd > /dev/null
echo "Setup complete, use ./bin/server.sh to start Timestamp Server"