========
SaltMaster with Syndic and API
========

Container with salt master running inside with syndic and minion and published api


Based on
======================
CentOS 7

How to use it
======================

``Docker compose``
-----------------

Modify docker-compose.yml
Run container with docker-compose up -d

``Docker run``
-----------------

Start container with:

.. code:: yaml

docker run -d --restart=unless-stopped -e SALT_SYNDIC_ID='SaltMaster' -e SALT_ENV='base' -e SALT_MASTER_PUBLISH='4505' -e SALT_MASTER_PORT='4506' -e SALT_API_PORT='8005' -e SALT_MOM_IP='salt.stack.local' -p 4506:4506 -p 4505:4505 -p 8005:8005 -v /opt/salt/base-etc/certs:/etc/pki/tls/certs:ro -v /opt/salt/base-etc/pki:/etc/salt/pki:ro -v /opt/salt/base-etc/master.d:/etc/salt/master.d -v /opt/salt/base:/opt/salt/base --name saltmaster smonko/salt-syndic-api


Maintainer
======================
Stefan Monko, monkostefan@gmail.com
