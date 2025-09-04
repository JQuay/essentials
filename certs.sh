# create root cert and key
```sh
openssl genrsa -out root.key 4096
openssl req -x509 -new -nodes -key root.key -sha256 -days 3650 -out root.crt -subj "/CN=MyRootCA"

```
# create intermediate key and certificate 

```sh
openssl genrsa -out intermediate.key 4096
openssl req -new -key intermediate.key -out intermediate.csr -subj "/CN=MyIntermediateCA"

openssl x509 -req -in intermediate.csr -CA root.crt -CAkey root.key -CAcreateserial \
-out intermediate.crt -days 1825 -sha256 \
-extfile <(printf "basicConstraints=CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid:always,issuer:always")

```

# create server cert (leaf)
```sh
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=app.example.com"

openssl x509 -req -in server.csr -CA intermediate.crt -CAkey intermediate.key -CAcreateserial \
-out server.crt -days 825 -sha256

```

# verify the chain
```sh
openssl verify -CAfile <(cat intermediate.crt root.crt) server.crt
```
✅ Output: server.crt: OK

# Build chain 

```sh
cat intermediate.crt root.crt > chain.crt
```

# create pkcs12 keystore
``` sh
openssl pkcs12 -export \
-inkey server.key \
-in server.crt \
-certfile chain.crt \
-out keystore.p12 \
-name tomcat \
-passout pass:changeit

```
# Convert to pkcs12 to JKS (Optional)

```sh
keytool -importkeystore \
-srckeystore keystore.p12 -srcstoretype PKCS12 \
-destkeystore keystore.jks -deststoretype JKS \
-srcstorepass changeit -deststorepass changeit
```

# Replace existing cert (renewed certificate)
#NB: This overwrites the .p12 with the new cert and keeps the same alias.
```sh
openssl pkcs12 -export \
  -inkey server.key \
  -in new_server.crt \
  -certfile chain.crt \
  -out keystore.p12 \
  -name tomcat \
  -passout pass:changeit
```


#Import another cert into the same .p12 (as trusted cert)
#Use keytool:
```sh
keytool -importcert \
  -trustcacerts \
  -alias new-ca \
  -file new_ca.crt \
  -keystore keystore.p12 \
  -storetype PKCS12 \
  -storepass changeit
```


# inspect keystore 
``` sh
keytool -list -v -keystore keystore.p12 -storetype PKCS12 -storepass changeit
```








