#!/bin/sh
# Creates a self-signed code-signing identity in a dedicated keychain.
# Signing every build with the same identity keeps the app's code
# requirement stable, so the login Keychain stops asking for the password
# after each rebuild. Run once; bundle.sh picks the identity up.
set -eu

name="LifemartBar Local Signing"
keychain="$HOME/Library/Keychains/lifemartbar-signing.keychain-db"
# Protects only this local signing key, not anything personal.
password="lifemartbar"

if [ -f "$keychain" ]; then
    echo "Signing keychain already exists: $keychain"
    exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/cert.conf" <<CONF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $name
[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
CONF

# /usr/bin/openssl (LibreSSL) writes a PKCS#12 that `security import` accepts.
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -config "$tmp/cert.conf" -keyout "$tmp/key.pem" -out "$tmp/cert.pem" 2>/dev/null
/usr/bin/openssl pkcs12 -export -name "$name" -inkey "$tmp/key.pem" -in "$tmp/cert.pem" \
    -out "$tmp/identity.p12" -passout "pass:$password"

security create-keychain -p "$password" "$keychain"
security set-keychain-settings "$keychain"
security import "$tmp/identity.p12" -k "$keychain" -P "$password" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple: -s -k "$password" "$keychain" >/dev/null

echo "Created \"$name\" in $keychain"
