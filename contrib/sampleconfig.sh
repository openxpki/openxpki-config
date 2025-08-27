#!/bin/bash

## DO NOT USE THIS SCRIPT FOR PRODUCTION SYSTEMS


# check if we are in docker
IS_DOCKER=0
PID=$(cat /run/openxpkid/openxpkid.pid)
if [ "$PID" -eq "1" ]; then
    IS_DOCKER=1
    if [ "$(whoami)" != "pkiadm" ]; then
        echo "#####################################################################"
        echo "#  Looks like you are running in docker                             #"
        echo "#  please start this script as pkiadm                               #"
        echo "#####################################################################"
        exit 1;
    fi
    # we expect that the cli is set up
    if ! oxi cli ping; then
        echo "#####################################################################"
        echo "#  Looks like you are running in docker but oxi cli was not set up  #"
        echo "#  check if the key setup of the pkiadm user                        #"
        echo "#####################################################################"
        exit 1;
    fi
fi;

set -e

FQDN=$(hostname -f)
GENERATION=$(date +%Y%m%d)
# consumed by clca
export PASSPHRASE="root"


test -d /opt/myperl/bin && export PATH=/opt/myperl/bin:$PATH

# try to download clca if not found in path
if [ -z "$(which clca)" ]; then
    # clca is required - try to download
    echo "Need clca command line ca tool, trying to download..."
    wget -q https://raw.githubusercontent.com/openxpki/clca/refs/heads/master/bin/clca -O clca
    mkdir -p /usr/local/bin/
    mv clca /usr/local/bin/
    chmod +x /usr/local/bin/clca
fi

# install locale if needed
# shellcheck disable=SC2126 # grep -c does not work with -e
HAS_LOCALE=$(locale -a | grep en_US | wc -l)
if [ "$HAS_LOCALE" == "0" ]; then
    sed -r "/en_US.UTF-8/d" -i /etc/locale.gen
    echo "en_US.UTF-8 UTF-8" >>  /etc/locale.gen
    dpkg-reconfigure --frontend=noninteractive locales
fi

if [ -z "$1" ]; then
   TMP_CA_DIR=$(mktemp -d)
   echo "Fully automated sample setup using tmpdir $TMP_CA_DIR"
elif [ -d "$1" ]; then
   TMP_CA_DIR=$1
   echo "Try to build hierarchy in $TMP_CA_DIR"
else
   echo "Given parameter is not a directory"
   exit 1;
fi

cd "$TMP_CA_DIR"

# prepare clca environment
mkdir etc/
cat <<EOF > etc/clca.cfg
# derived paths
CADBDIR=\$CA_HOME/ca
CACERT=\$CADBDIR/cacert.pem
CAPRIVDIR=\$CA_HOME/private
CERTDIR=\$CA_HOME/certs
CRLDIR=\$CA_HOME/crl

ENGINE=openssl

# Path to OpenSSL binary
OPENSSL=/usr/bin/openssl

######################################################################
# Path to OpenSSL configuration
CNF=\$CA_HOME/etc/openssl.cnf

# if HSM protected keys are used this may also be the key ident
ROOTKEYNAME=cakey.pem

# Default settings for genkey subcommand
# Public key algorithm (rsa, ec)
DEFAULT_PUBKEY_ALGORITHM=ec
# RSA key size (bits)
DEFAULT_RSA_KEYSIZE=3072
# EC curve name (see openssl ecparam -list_curves)
DEFAULT_EC_CURVE=secp384r1
# Private key encryption algorithm
DEFAULT_ENC_ALGORITHM=aes256

get_passphrase() {
    echo \$PASSPHRASE
}
# Default CA validity in days (unless specified via --startdate and --enddate)
CA_VALIDITY=3650

# Randomize certificate serial numbers (default: off)
RANDOMIZE_SERIAL=1

# do not ask for confirmation when issuing certificates
BATCH=1
EOF

cat <<EOF > etc/openssl.cnf
HOME                    = .

oid_section             = new_oids
default_md              = sha256

dir                     = .
certs                   = \$dir/certs
crl_dir                 = \$dir/crl
database                = \$dir/ca/index.txt
new_certs_dir           = \$dir/certs

certificate             = \$dir/ca/cacert.pem
serial                  = \$dir/ca/serial
crl                     = \$dir/crl/ca.crl
crlnumber               = \$dir/ca/crlnumber.txt

RANDFILE                = \$dir/private/.rand    # private random number file

unique_subject          = no
email_in_dn             = no

default_days            = 365                   # how long to certify for
default_crl_days        = 365                   # how long before next CRL
preserve                = no                    # keep passed DN ordering

policy                  = policy_match

[ new_oids ]

####################################################################
[ ca ]
default_ca              = CA_default            # The default ca section

####################################################################
[ CA_default ]
x509_extensions         = root_ext              # The extensions to add to issued certs
crl_extensions          = root_crl_ext

# For the CA policy
[ policy_match ]
countryName             = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
domainComponent         = optional

####################################################################
[ req ]
# settings for 'ca initialize' or 'clca certify ...'
distinguished_name      = root_dn
prompt                  = no
x509_extensions         = root_ext
string_mask             = nombstr

[ level2 ]
# settings for 'clca --profile level2 certify ...'
prompt                  = no
x509_extensions         = level2_ext
string_mask             = nombstr

[ endentity ]
# settings for 'clca --profile endentity --subject "/DC=org/DC=openxpki/O=OpenXPKI/CN=example.openxpki.org" certify ...'
prompt                  = no
x509_extensions         = endentity_ext
string_mask             = nombstr

[ root_dn ]
countryName             = DE
organizationName        = OpenXPKI
organizationalUnitName  = PKI
commonName              = OpenXPKI Root DUMMY CA ${GENERATION}

# extensions for self-signed root certificate
[ root_ext ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
basicConstraints        = critical,CA:true
keyUsage                = critical, cRLSign, keyCertSign
# Certificate Policies OID if required
# certificatePolicies   = ia5org,1.3.6.1.4.1.xxxxx

# extensions for issued certificates
[ level2_ext ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
basicConstraints        = critical,CA:true,pathlen:0
keyUsage                = critical, cRLSign, keyCertSign
# Certificate Policies OID if required
# certificatePolicies   = ia5org,1.3.6.1.4.1.xxxxx
# CDPs (recommended for Level 2 CAs)
# crlDistributionPoints = URI:http://example.com/openxpki/crl/root_caX.crl

# extensions for issued certificates
[ endentity_ext ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
basicConstraints        = critical,CA:false
keyUsage                = critical, digitalSignature, keyEncipherment
extendedKeyUsage        = serverAuth, clientAuth
# Certificate Policies OID if required
# certificatePolicies   = ia5org,1.3.6.1.4.1.xxxxx
# CDPs (recommended for Level 2 CAs)
# crlDistributionPoints = URI:http://example.com/openxpki/crl/level2_caX.crl

[ root_crl_ext ]
# set this if you have an issuer alternative name
# issuerAltName         = issuer:copy
authorityKeyIdentifier  = keyid:always,issuer:always
EOF

# generate root key and run initialize
mkdir private
clca genkey
clca initialize
cp ca/cacert.pem rootca.crt

# create issuing ca key and csr
clca genkey --keyfile issuingca.key
openssl req -new -key issuingca.key -passin env:PASSPHRASE -out issuingca.csr -subj "/CN=OpenXPKI Issuing DUMMY CA $GENERATION"
clca certify --profile level2 --days 3649 issuingca.csr

if [ ! -e newcert.pem ]; then
    echo "Something went wrong :("
    exit;
fi
mv newcert.pem issuingca.crt

# also generate a certificate for the webserver and the ratoken
# use rsa for ratoken to work with SCEP
PASSPHRASE=secret clca genkey  --algorithm rsa --keyfile ratoken.key
openssl req -new -key ratoken.key -passin pass:secret -out ratoken.csr -subj "/CN=Internal RA"
clca certify --profile endentity --days 365 ratoken.csr
mv newcert.pem ratoken.crt

clca genkey --protect none --keyfile webserver.key
openssl req -new -key webserver.key -out webserver.csr -subj "/CN=$FQDN"
clca certify --profile endentity --days 365 --san "DNS:$FQDN" webserver.csr
mv newcert.pem webserver.crt

# generate oxi admin key
clca genkey --protect none --curve prime256v1 --keyfile client.key
PUBKEY=$(openssl pkey -in client.key -pubout | sed "s/^/      /")
cat <<EOF > cli.yaml
auth:
  admin:
    role: System
    key: >
$PUBKEY
EOF

if [ -e "/etc/openxpki/config.d/system/crypto.yaml" ] ; then
    SVAULT=$(openssl rand -hex 32)
    sed -r "s/value: .*##SVAULTKEY##/value: ${SVAULT}/" \
        /etc/openxpki/config.d/system/crypto.yaml > crypto.yaml
fi

# do not proceed if a folder was given
if [ -n "$1" ]; then
    echo "#####################################################################"
    echo "#                                                                   #"
    echo "#  Artefacts have been created in given directory - you need to...  #"
    echo "#                                                                   #"
    echo "#  Copy cli.yaml and crypto.yaml to /etc/openxpki/config.d/system/  #"
    echo "#  Copy client.key to /home/openxpki/.oxi/client.key                #"
    echo "#  Make sure to set proper permissions                              #"
    echo "#                                                                   #"
    echo "#  Import the keys and certificates using *oxi token add ...*       #"
    echo "#                                                                   #"
    echo "#####################################################################"
    exit 0;
fi


# cli setup and server restart not required in docker
if [ "$IS_DOCKER" == "0" ]; then
    # install oxi client key
    cp cli.yaml /etc/openxpki/config.d/system/
    mkdir -p ~/.oxi/
    # shellcheck disable=SC2225
    cp client.key ~/.oxi/

    # install crypto.yaml
    test -e crypto.yaml && (cat crypto.yaml > /etc/openxpki/config.d/system/crypto.yaml)

    echo "#####################################################################"
    echo "#                                                                   #"
    echo "#  (re)starting system now to proceed with import                   #"
    echo "#                                                                   #"
    echo "#####################################################################"

    # restart to activate key
    systemctl restart openxpki-serverd

    # shellcheck disable=SC2034
    for ii in $(seq 1 5); do
        echo "waiting for system to be ready ($ii/5)..."
        sleep 5;
        test -e /run/openxpkid/openxpkid.sock && break;
    done;
fi

# test connection
oxi cli ping

# import the root as signer token in root realm
oxi token add --realm rootca --type certsign --cert rootca.crt

# import issuing ca
oxi token add --realm democa --type certsign --cert issuingca.crt --key issuingca.key

# load SCEP token
oxi token add --realm democa --type scep --cert ratoken.crt --key ratoken.key

# create initial CRL
oxi workflow create --realm democa --type crl_issuance

# check if we are in docker as we do not need to setup the webserver
if [ "$IS_DOCKER" == "1" ]; then
    exit 0;
fi;

# Setup the Webserver (this is usually already done by the package
# installer but only if apache was installed before openxpki)
a2enmod headers macro proxy proxy_http rewrite ssl || /bin/true
a2ensite openxpki || /bin/true
a2dissite 000-default default-ssl || /bin/true

if [ ! -e "/etc/openxpki/tls/chain" ]; then
    # shellcheck disable=SC2174
    mkdir -m755 -p /etc/openxpki/tls/chain
    cp ca/cacert.pem /etc/openxpki/tls/chain/
    cp issuingca.crt /etc/openxpki/tls/chain/
    c_rehash /etc/openxpki/tls/chain/
fi

if [ ! -e "/etc/openxpki/tls/endentity/openxpki.crt" ]; then
    # shellcheck disable=SC2174
    mkdir -m755 -p /etc/openxpki/tls/endentity
    # shellcheck disable=SC2174
    mkdir -m700 -p /etc/openxpki/tls/private
    cp webserver.crt /etc/openxpki/tls/endentity/openxpki.crt
    cat issuingca.crt >> /etc/openxpki/tls/endentity/openxpki.crt
    cp webserver.key /etc/openxpki/tls/private/openxpki.pem
    chmod 400 /etc/openxpki/tls/private/openxpki.pem
    service apache2 restart
fi

cp issuingca.crt /etc/ssl/certs
cp ca/cacert.pem /etc/ssl/certs
c_rehash /etc/ssl/certs

systemctl start openxpki-clientd

echo "OpenXPKI configuration should be and server should be running..."
echo ""
echo "Thanks for using OpenXPKI - Have a nice day ;)"
echo ""
