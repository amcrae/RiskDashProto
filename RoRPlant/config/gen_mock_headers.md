# Homebrew signing scheme
This is simply for understanding the concepts and prototyping.
For simplicity it does not use any public key crypto.

* The data could be any string but is assumed JSON here.
* Signing is done by salting the hash with a secret string to be prepended to the data and separated from it by a pipe char.
* The SHA1 will be used to compute signature value.
* The signed value is the original data, followed by pipe char, followed by the signature value.

## Mock Claims token for user2@example.com

* JSON data == '{upn: "user2@example.com", memberOf: [ "X_STAFF_TECH_GRP", "X_SOMETHING_ELSE" ] }'
* The secret hash salt == 'SECRET'

```console
$ echo 'SECRET|{upn: "user2@example.com", memberOf: [ "X_STAFF_TECH_GRP", "X_SOMETHING_ELSE" ] }'|sha1sum
e6c21ee693fbc53a5d7f01cf08fdca5c69d11188
```

Append signature to plaintext value with a pipe separator too, then base64 encode. The base64 encoding will prevent conflicts between values containing commas (eg JSON) and the RFC9110 HTTP spec about commas used for multi-membered headers.  
Specfiying output on a single line is used to adhere to the RFC9112 instruction to never split field values over multiple lines.

```console
$ echo '{upn: "user2@example.com", memberOf: [ "X_STAFF_TECH_GRP", "X_SOMETHING_ELSE" ] }|e6c21ee693fbc53a5d7f01cf08fdca5c69d11188'|base64 -w 0
e3VwbjogInVzZXIyQGV4YW1wbGUuY29tIiwgbWVtYmVyT2Y6IFsgIlhfU1RBRkZfVEVDSF9HUlAiLCAiWF9TT01FVEhJTkdfRUxTRSIgXSB9fGU2YzIxZWU2OTNmYmM1M2E1ZDdmMDFjZjA4ZmRjYTVjNjlkMTExODgK
```

As this is a simplistic signature scheme, the validation is:
1. Decode base64 field value.
2. Use the last pipe char to split into data|sig
3. Recompute the sig using the data and secret salt as before.
4. Check the hex strings of the recomputed sig and received sig match (case insensitive).

When writing the script to automate the above steps some fixes and adjustments had to be made:
* echo adds a newline which alters the hash, but is prevented with the '-n' option.
* The data in the first example was javascript, not JSON proper.
This is why the output of the script used in the example MockProxy config is not the same as above.

`homebrew_sign.sh`:  
```bash
#!/bin/bash
SECRET=$1
read DATA
PREFIXED="$SECRET|$DATA"
echo data to sign is:$PREFIXED
SIGNATURE=$(echo -n $PREFIXED | sha1sum - | awk -p '{print $1}')
echo signature is ${SIGNATURE}
B64=$(echo "${DATA}|${SIGNATURE}" | base64 -w 0)
echo signed and encoded: $B64
```
e.g. 
```console
$ echo '{"upn": "user2@example.com", "memberOf": [ "X_STAFF_TECH_GRP", "X_SOMETHING_ELSE" ] }'|./homebrew_sign.sh SECRET
data to sign is:SECRET|{"upn": "user2@example.com", "memberOf": [ "X_STAFF_TECH_GRP", "X_SOMETHING_ELSE" ] }
signature is 671f1797e075630a2c85895ee239591878b709fe
signed and encoded: eyJ1cG4iOiAidXNlcjJAZXhhbXBsZS5jb20iLCAibWVtYmVyT2YiOiBbICJYX1NUQUZGX1RFQ0hfR1JQIiwgIlhfU09NRVRISU5HX0VMU0UiIF0gfXw2NzFmMTc5N2UwNzU2MzBhMmM4NTg5NWVlMjM5NTkxODc4YjcwOWZl
```

## Mock Access token for user2@example.com
script output
```console
JSON Data == '{"fullname": "User McTwo", "upn": "user2@example.com", "mail": "user2@example.com", "phone":"0491 570 156", "issuer":"heyjust.trustus.com"}'  
data to sign is: SECRET|{"fullname": "User McTwo", "upn": "user2@example.com", "mail": "user2@example.com", "phone":"0491 570 156", "issuer":"heyjust.trustus.com"}  
signature is d67269266c885266224ce4ecd7dc49d41b2254a8
signed and encoded: eyJmdWxsbmFtZSI6ICJVc2VyIE1jVHdvIiwgInVwbiI6ICJ1c2VyMkBleGFtcGxlLmNvbSIsICJtYWlsIjogInVzZXIyQGV4YW1wbGUuY29tIiwgInBob25lIjoiMDQ5MSA1NzAgMTU2IiwgImlzc3VlciI6ImhleWp1c3QudHJ1c3R1cy5jb20ifXxkNjcyNjkyNjZjODg1MjY2MjI0Y2U0ZWNkN2RjNDlkNDFiMjI1NGE4
```
