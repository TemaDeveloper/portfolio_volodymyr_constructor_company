#!/bin/bash

openssl genpkey -algorithm RSA -out key.pem

openssl req -new -key key.pem -out request.csr

openssl x509 -req -days 365 -in request.csr -signkey key.pem -out cert.pem

rm request.csr

echo "Generated key.pem and cert.pem"
