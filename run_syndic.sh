#!/bin/bash

# create empty conf
mkdir -p /etc/salt/minion.d
mkdir -p /etc/salt/master.d

touch /etc/salt/minion.d/syndic.conf
touch /etc/salt/minion.d/minion_port.conf
touch /etc/salt/master.d/master_port.conf
touch /etc/salt/master.d/api.conf
touch /etc/salt/master.d/pillar_roots.conf
touch /etc/salt/master.d/file_roots.conf

# Setup syndic
echo "id: $SALT_SYNDIC_ID" > /etc/salt/minion.d/syndic.conf
echo "master: localhost" >> /etc/salt/minion.d/syndic.conf
echo "syndic_master: $SALT_MOM_IP" >> /etc/salt/master.d/syndic.conf
echo "master_port: $SALT_MASTER_PORT" >> /etc/salt/minion.d/minion_port.conf
echo "publish_port: $SALT_MASTER_PUBLISH" >> /etc/salt/minion.d/minion_port.conf
echo "publish_port: $SALT_MASTER_PUBLISH" >> /etc/salt/master.d/master_port.conf
echo "ret_port: $SALT_MASTER_PORT" >> /etc/salt/master.d/master_port.conf


echo "rest_cherrypy:" >> /etc/salt/master.d/api.conf
echo "  port: $SALT_API_PORT" >> /etc/salt/master.d/api.conf
echo "  ssl_crt: /etc/pki/tls/certs/localhost.crt" >> /etc/salt/master.d/api.conf
echo "  ssl_key: /etc/pki/tls/certs/localhost.key" >> /etc/salt/master.d/api.conf

mkdir -p /opt/salt/$SALT_ENV
mkdir -p /opt/salt/$SALT_ENV/pillars
mkdir -p /opt/salt/$SALT_ENV/states
mkdir -p /opt/salt/$SALT_ENV/artifacts
mkdir -p /opt/salt/$SALT_ENV/formulas
echo "pillar_roots:" >> /etc/salt/master.d/pillar_roots.conf
echo "  $SALT_ENV:" >> /etc/salt/master.d/pillar_roots.conf
echo "    - /opt/salt/$SALT_ENV/pillars" >> /etc/salt/master.d/pillar_roots.conf
echo "file_roots:" >> /etc/salt/master.d/file_roots.conf
echo "  $SALT_ENV:" >> /etc/salt/master.d/file_roots.conf
echo "    - /opt/salt/$SALT_ENV/states" >> /etc/salt/master.d/file_roots.conf
echo "    - /opt/salt/$SALT_ENV/artifacts" >> /etc/salt/master.d/file_roots.conf
echo "    - /opt/salt/$SALT_ENV/formulas" >> /etc/salt/master.d/file_roots.conf

# Start the first process
/usr/bin/salt-master -d
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start salt-master: $status"
  exit $status
fi

/usr/bin/salt-minion -d
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start salt-master: $status"
  exit $status
fi

/usr/bin/salt-api -d
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start salt-master: $status"
  exit $status
fi

# Start the second process
/usr/bin/salt-syndic -d
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start salt-syndic: $status"
  exit $status
fi

for (( c=1; c<=20; c++ ))
do
   salt-key -A -y
done

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container will exit with an error
# if it detects that either of the processes has exited.
# Otherwise it will loop forever, waking up every 60 seconds

while /bin/true; do
  ps aux |grep salt-master |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep salt-syndic |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they will exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit -1
  fi
  sleep 60
done
