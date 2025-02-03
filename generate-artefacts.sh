#!/bin/bash

ROOT_CA_CERT="/opt/fabric/network/ca-cert.pem"
FABRIC_CA_CLIENT_HOME="/opt/fabric/network/ca-client"
FABRIC_CA_SERVER_PORT="7054"
FABRIC_CA_SERVER_NAME="FabricCA"
FABRIC_NETWORK_HOME="/opt/fabric/network"
HOSTNAME=$(hostname)

# Function to create directories
create_directories() {
  echo "Creating directories..."
  mkdir -p $FABRIC_NETWORK_HOME/{ca-client,ca-server}/admin
  mkdir -p $FABRIC_NETWORK_HOME/{peer,orderer,client,orgadmin}/msp
  mkdir -p $FABRIC_NETWORK_HOME/tls
}

# Function to register identities in the CA
register_identity() {
  local identity_name=$1
  local identity_secret=$2
  local identity_type=$3
  echo "Registering identity: $identity_name"
  fabric-ca-client register --caname $FABRIC_CA_SERVER_NAME \
    --id.name $identity_name --id.secret $identity_secret --id.type $identity_type \
    --tls.certfiles $ROOT_CA_CERT
}

# Function to enroll identities
enroll_identity() {
  local identity_name=$1
  local identity_secret=$2
  local identity_type=$3
  local msp_dir=$4
  echo "Enrolling: $identity_name"
  fabric-ca-client enroll -u https://$identity_name:$identity_secret@localhost:$FABRIC_CA_SERVER_PORT \
    --caname $FABRIC_CA_SERVER_NAME -M $msp_dir --tls.certfiles $ROOT_CA_CERT
}

# Function to generate TLS certificates
generate_tls_certificates() {
  local identity_name=$1
  local msp_dir=$2
  echo "Generating TLS certificates for: $identity_name"
  fabric-ca-client enroll -u https://$identity_name:$identity_secret@localhost:$FABRIC_CA_SERVER_PORT \
    --caname $FABRIC_CA_SERVER_NAME -M $msp_dir --enrollment.profile tls \
    --csr.hosts $HOSTNAME --csr.hosts localhost --tls.certfiles $ROOT_CA_CERT
}

# Function to create the MSP configuration file
create_msp_config() {
  local config_file="$FABRIC_NETWORK_HOME/ca-client/admin/msp/config.yaml"
  echo "Creating MSP configuration..."
  echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
      Certificate: cacerts/localhost-7054-FabricCA.pem
      OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
      Certificate: cacerts/localhost-7054-FabricCA.pem
      OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
      Certificate: cacerts/localhost-7054-FabricCA.pem
      OrganizationalUnitIdentifier: admin' > $config_file
}

# Function to copy certificates
copy_certificates() {
  echo "Copying certificates..."
  mkdir -p $FABRIC_NETWORK_HOME/{peer,orderer,client,orgadmin}/msp/tlscacerts
  cp $ROOT_CA_CERT $FABRIC_NETWORK_HOME/ca-client/admin/msp/tlscacerts/
  cp $ROOT_CA_CERT $FABRIC_NETWORK_HOME/peer/msp/tlscacerts/
  cp $ROOT_CA_CERT $FABRIC_NETWORK_HOME/client/msp/tlscacerts/
  cp $ROOT_CA_CERT $FABRIC_NETWORK_HOME/orderer/msp/tlscacerts/

  cp $FABRIC_NETWORK_HOME/ca-client/admin/msp/config.yaml $FABRIC_NETWORK_HOME/peer/msp/
  cp $FABRIC_NETWORK_HOME/ca-client/admin/msp/config.yaml $FABRIC_NETWORK_HOME/client/msp/
}

# Function to move keys to the correct directory
move_keys() {
  echo "Moving keys to the correct location..."
  mv $FABRIC_NETWORK_HOME/ca-client/admin/msp/keystore/* $FABRIC_NETWORK_HOME/ca-client/admin/msp/keystore/server.key
  mv $FABRIC_NETWORK_HOME/peer/msp/keystore/* $FABRIC_NETWORK_HOME/peer/msp/keystore/server.key
  mv $FABRIC_NETWORK_HOME/client/msp/keystore/* $FABRIC_NETWORK_HOME/client/msp/keystore/server.key
}

# Function to copy TLS certificates
copy_tls_certificates() {
  echo "Copying TLS certificates..."
  cp $FABRIC_NETWORK_HOME/ca-client/admin/tls/tlscacerts/* $FABRIC_NETWORK_HOME/tls/ca.crt
  cp $FABRIC_NETWORK_HOME/ca-client/admin/tls/signcerts/* $FABRIC_NETWORK_HOME/tls/server.crt
  cp $FABRIC_NETWORK_HOME/ca-client/admin/tls/keystore/* $FABRIC_NETWORK_HOME/tls/server.key
}

# Function to start the Fabric CA Server
start_fabric_ca_server() {
  echo "Starting the Fabric CA Server..."
  fabric-ca-server start -b admin:adminpwd -d --port $FABRIC_CA_SERVER_PORT &
  sleep 5
}

main() {
  create_directories
  start_fabric_ca_server

  # Register identities
  register_identity "peer0-org1" "peer0pw" "peer"
  register_identity "admin-org1" "adminpwd" "admin"
  register_identity "client-user" "clientpw" "client"

  # Enroll identities
  enroll_identity "admin-org1" "adminpwd" "admin" "$FABRIC_NETWORK_HOME/ca-client/admin/msp"
  enroll_identity "peer0-org1" "peer0pw" "peer" "$FABRIC_NETWORK_HOME/peer/msp"
  enroll_identity "client-user" "clientpw" "client" "$FABRIC_NETWORK_HOME/client/msp"

  # Generate TLS certificates
  generate_tls_certificates "admin-org1" "$FABRIC_NETWORK_HOME/ca-client/admin/tls"
  generate_tls_certificates "peer0-org1" "$FABRIC_NETWORK_HOME/peer/tls"
  generate_tls_certificates "client-user" "$FABRIC_NETWORK_HOME/client/tls"

  # Create MSP configuration file
  create_msp_config

  # Copy certificates
  copy_certificates

  # Move keys to the correct location
  move_keys

  # Copy TLS certificates
  copy_tls_certificates

  echo "Fabric CA setup completed successfully!"
}

main
