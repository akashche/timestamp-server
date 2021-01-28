#!/bin/bash

set -e
#set -x

CA_START_DATE=20150101000000Z
CA_END_DATE=20250101000000Z
TSA_START_DATE=20180101000000Z
TSA_END_DATE=20190101000000Z
SIGN_START_DATE=20150101000000Z
SIGN_END_DATE=20250101000000Z

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
openssl req -new -config "$SERVER_DIR"/conf/openssl.conf -out rootca.csr -keyout ./CA/private/rootca.key -passout pass:1234

# sign CA
openssl ca -selfsign -config "$SERVER_DIR"/conf/openssl.conf -in rootca.csr -out ./CA/rootca.pem -extensions ca_ext -startdate $CA_START_DATE -enddate $CA_END_DATE -passin pass:1234 -batch

# bare CA
openssl x509 -in ./CA/rootca.pem -outform PEM -out ./CA/rootca-bare.pem

# DER CA
openssl x509 -in ./CA/rootca.pem -outform DER -out ./CA/rootca.der

# TSA directories
mkdir -p ./TSA/private
echo 01 > ./TSA/tsa_serial

# TSA request
openssl req -new -newkey rsa:2048 -subj "/C=US/O=Test Inc./OU=Engineering/CN=Test TSA" -keyout ./TSA/private/tsa.key -out tsa.csr -passout pass:1234

# sign TSA
openssl ca -config "$SERVER_DIR"/conf/openssl.conf -in tsa.csr -out ./TSA/tsa.pem -extensions tsa_ext -startdate $TSA_START_DATE -enddate $TSA_END_DATE -passin pass:1234 -batch

# bare TSA
openssl x509 -in ./TSA/tsa.pem -outform PEM -out ./TSA/tsa-bare.pem

# TSA chain
cat ./TSA/tsa.pem ./CA/rootca-bare.pem > ./TSA/tsa-chain.pem

# CS request
openssl req -new -newkey rsa:2048 -subj "/C=US/O=Test Inc./OU=Engineering/CN=Test Signer" -keyout sign.key -out sign.csr -passout pass:1234

# sign CS
openssl ca -config "$SERVER_DIR"/conf/openssl.conf -in sign.csr -out sign.pem -extensions sign_ext -startdate $SIGN_START_DATE -enddate $SIGN_END_DATE -passin pass:1234 -batch

# create keystore
openssl pkcs12 -export -in sign.pem -inkey sign.key -out sign.p12 -name "Test Signer" -caname "Test Root CA" -chain -CAfile ./CA/rootca.pem -passin pass:1234 -passout pass:1234

# add CA to keystore
keytool -importcert -file ./CA/rootca.der -keystore sign.p12 -alias "Test Root CA" -storepass 1234 -storetype pkcs12 -noprompt

popd > /dev/null
echo "Setup complete, use ./bin/start.sh to start Timestamp Server"