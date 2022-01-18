#!/bin/bash

apt-get install -y openssl openjdk-8-jdk wget unzip bc

wget https://download.jboss.org/wildfly/18.0.1.Final/wildfly-18.0.1.Final.zip -O /tmp/wildfly-18.0.1.Final.zip
unzip -q -o /tmp/wildfly-18.0.1.Final.zip -d /opt/
ln -snf /opt/wildfly-18.0.1.Final /opt/wildfly

sed -i 's|.*org.jboss.resteasy.resteasy-crypto.*||' /opt/wildfly/modules/system/layers/base/org/jboss/as/jaxrs/main/module.xml
rm -rf /opt/wildfly/modules/system/layers/base/org/jboss/resteasy/resteasy-crypto

rm -f /opt/wildfly/bin/standalone.conf

cat <<EOF > /opt/wildfly/bin/standalone.conf
if [ "x$JBOSS_MODULES_SYSTEM_PKGS" = "x" ]; then
   JBOSS_MODULES_SYSTEM_PKGS="org.jboss.byteman"
fi

if [ "x$JAVA_OPTS" = "x" ]; then
   JAVA_OPTS="-Xms<HEAP_SIZE>m -Xmx<HEAP_SIZE>m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m"
   JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true"
   JAVA_OPTS="$JAVA_OPTS -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS"
   JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"
   JAVA_OPTS="$JAVA_OPTS -Djboss.tx.node.id=<TX_NODE_ID>"
   JAVA_OPTS="$JAVA_OPTS -Djdk.tls.ephemeralDHKeySize=2048"
else
   echo "JAVA_OPTS already set in environment; overriding default settings with values: $JAVA_OPTS"
fi
EOF


sed -i -e 's/<HEAP_SIZE>/2048/g' /opt/wildfly/bin/standalone.conf
sed -i -e "s/<TX_NODE_ID>/$(od -A n -t d -N 1 /dev/urandom | tr -d ' ')/g" /opt/wildfly/bin/standalone.conf

cp /opt/wildfly/docs/contrib/scripts/systemd/launch.sh /opt/wildfly/bin
cp /opt/wildfly/docs/contrib/scripts/systemd/wildfly.service /etc/systemd/system
mkdir /etc/wildfly
cp /opt/wildfly/docs/contrib/scripts/systemd/wildfly.conf /etc/wildfly
systemctl daemon-reload
useradd -M wildfly
chown -R wildfly:wildfly /opt/wildfly-18.0.1.Final/

systemctl start wildfly

echo '#!/bin/sh' > /usr/bin/wildfly_pass
echo "echo '$(openssl rand -base64 24)'" >> /usr/bin/wildfly_pass
chown wildfly:wildfly /usr/bin/wildfly_pass
chmod 700 /usr/bin/wildfly_pass

wildfly_check() {
  DURATION_SECONDS=30
  if [ ! -z "$1" ]; then
    DURATION_SECONDS="$1"
  fi
  DURATION=$(echo "$DURATION_SECONDS / 5" | bc)

  echo "wait ${DURATION_SECONDS}s for start up wildfly"
  cd $INSTALL_DIRECTORY || exit 1
  for i in `seq 1 $DURATION`; do
    /opt/wildfly/bin/jboss-cli.sh --connect ":read-attribute(name=server-state)" | grep "result" | awk '{ print $3; }'|grep running
    if [ $? -eq 0 ]; then
      return 0
    fi
    sleep 5
  done
  echo "wildfly not started after ${DURATION_SECONDS}s, exit"
  exit 1
}

wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=elytron/credential-store=defaultCS:add(location=credentials, relative-to=jboss.server.config.dir, credential-reference={clear-text="{EXT}/usr/bin/wildfly_pass", type="COMMAND"}, create=true)'

wget https://downloads.mariadb.com/Connectors/java/latest/mariadb-java-client-2.3.0.jar -O /opt/wildfly/standalone/deployments/mariadb-java-client.jar
chown wildfly:wildfly /opt/wildfly/standalone/deployments/mariadb-java-client.jar
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check
/opt/wildfly/bin/jboss-cli.sh --connect "/subsystem=elytron/credential-store=defaultCS:add-alias(alias=dbPassword, secret-value=\"${EJBCA_MYSQL_PASSWORD}\")"
/opt/wildfly/bin/jboss-cli.sh --connect 'data-source add --name=ejbcads --driver-name="mariadb-java-client.jar" --connection-url="jdbc:mysql://127.0.0.1:3306/ejbca" --jndi-name="java:/EjbcaDS" --use-ccm=true --driver-class="org.mariadb.jdbc.Driver" --user-name="ejbca" --credential-reference={store=defaultCS, alias=dbPassword} --validate-on-match=true --background-validation=false --prepared-statements-cache-size=50 --share-prepared-statements=true --min-pool-size=5 --max-pool-size=150 --pool-prefill=true --transaction-isolation=TRANSACTION_READ_COMMITTED --check-valid-connection-sql="select 1;"'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=remoting/http-connector=http-remoting-connector:write-attribute(name=connector-ref,value=remoting)'
/opt/wildfly/bin/jboss-cli.sh --connect '/socket-binding-group=standard-sockets/socket-binding=remoting:add(port=4447,interface=management)'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/http-listener=remoting:add(socket-binding=remoting,enable-http2=true)'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=logging/logger=org.ejbca:add(level=INFO)'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=logging/logger=org.cesecore:add(level=INFO)'

cat <<EOF > /etc/cron.daily/wildfly
#!/bin/sh
# Remove log files older than 7 days
find /opt/wildfly/standalone/log/ -type f -mtime +7 -name 'server.log*' -execdir rm -- '{}' \;
EOF
chmod +x /etc/cron.daily/wildfly

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/http-listener=default:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/https-listener=https:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/socket-binding-group=standard-sockets/socket-binding=http:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/socket-binding-group=standard-sockets/socket-binding=https:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/interface=http:add(inet-address="0.0.0.0")'
/opt/wildfly/bin/jboss-cli.sh --connect '/interface=httpspub:add(inet-address="0.0.0.0")'
/opt/wildfly/bin/jboss-cli.sh --connect '/interface=httpspriv:add(inet-address="0.0.0.0")'
/opt/wildfly/bin/jboss-cli.sh --connect '/socket-binding-group=standard-sockets/socket-binding=http:add(port="8080",interface="http")'
/opt/wildfly/bin/jboss-cli.sh --connect '/socket-binding-group=standard-sockets/socket-binding=httpspub:add(port="8442",interface="httpspub")'
/opt/wildfly/bin/jboss-cli.sh --connect '/socket-binding-group=standard-sockets/socket-binding=httpspriv:add(port="8443",interface="httpspriv")'

/opt/wildfly/bin/jboss-cli.sh --connect "/subsystem=elytron/credential-store=defaultCS:add-alias(alias=httpsKeystorePassword, secret-value=\"${EJBCA_INSTALL_HTTPSSERVER_PASSWORD}\")"
/opt/wildfly/bin/jboss-cli.sh --connect "/subsystem=elytron/credential-store=defaultCS:add-alias(alias=httpsTruststorePassword, secret-value=\"changeit\")"
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=elytron/key-store=httpsKS:add(path="keystore/keystore.jks",relative-to=jboss.server.config.dir,credential-reference={store=defaultCS, alias=httpsKeystorePassword},type=JKS)'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=elytron/key-store=httpsTS:add(path="keystore/truststore.jks",relative-to=jboss.server.config.dir,credential-reference={store=defaultCS, alias=httpsTruststorePassword},type=JKS)'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=elytron/key-manager=httpsKM:add(key-store=httpsKS,algorithm="SunX509",credential-reference={store=defaultCS, alias=httpsKeystorePassword})'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=elytron/trust-manager=httpsTM:add(key-store=httpsTS)'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=elytron/server-ssl-context=httpspub:add(key-manager=httpsKM,protocols=["TLSv1.2"],use-cipher-suites-order=false,cipher-suite-filter="TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256")'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=elytron/server-ssl-context=httpspriv:add(key-manager=httpsKM,protocols=["TLSv1.2"],use-cipher-suites-order=false,cipher-suite-filter="TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",trust-manager=httpsTM,need-client-auth=true)'

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/http-listener=http:add(socket-binding="http", redirect-socket="httpspriv")'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/https-listener=httpspub:add(socket-binding="httpspub", ssl-context="httpspub", max-parameters=2048)'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/https-listener=httpspriv:add(socket-binding="httpspriv", ssl-context="httpspriv", max-parameters=2048)'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/system-property=org.apache.catalina.connector.URI_ENCODING:add(value="UTF-8")'
/opt/wildfly/bin/jboss-cli.sh --connect '/system-property=org.apache.catalina.connector.USE_BODY_ENCODING_FOR_QUERY_STRING:add(value=true)'
/opt/wildfly/bin/jboss-cli.sh --connect '/system-property=org.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH:add(value=true)'
/opt/wildfly/bin/jboss-cli.sh --connect '/system-property=org.apache.tomcat.util.http.Parameters.MAX_COUNT:add(value=2048)'
/opt/wildfly/bin/jboss-cli.sh --connect '/system-property=org.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH:add(value=true)'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=webservices:write-attribute(name=wsdl-host, value=jbossws.undefined.host)'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=webservices:write-attribute(name=modify-wsdl-address, value=true)'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/host=default-host/location="\/":remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/configuration=handler/file=welcome-content:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

rm -rf /opt/wildfly/welcome-content/

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/configuration=filter/rewrite=redirect-to-app:add(redirect=true,target="/ejbca/")'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/host=default-host/filter-ref=redirect-to-app:add(predicate="method(GET) and not path-prefix(/ejbca,/crls,/certificates,/.well-known) and not equals({\%{LOCAL_PORT}, 4447})")'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/configuration=filter/rewrite=crl-rewrite:add(target="/ejbca/publicweb/crls/$${1}")'
/opt/wildfly/bin/jboss-cli.sh --connect "/subsystem=undertow/server=default-server/host=default-host/filter-ref=crl-rewrite:add(predicate=\"method(GET) and regex('/crls/(.*)')\")"
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=ee/service=default-bindings:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect 'data-source remove --name=ExampleDS'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=jdr:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=sar:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=jmx:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=pojo:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=ee-security:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=microprofile-metrics-smallrye:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=microprofile-health-smallrye:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=microprofile-opentracing-smallrye:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/extension=org.wildfly.extension.microprofile.health-smallrye:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/extension=org.wildfly.extension.microprofile.opentracing-smallrye:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/extension=org.jboss.as.jdr:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/extension=org.jboss.as.jmx:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/extension=org.jboss.as.sar:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/extension=org.jboss.as.pojo:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/extension=org.wildfly.extension.ee-security:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=distributable-web:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=infinispan/cache-container=ejb:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=infinispan/cache-container=server:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=ejb3/cache=distributable:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=ejb3/passivation-store=infinispan:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=security/security-domain=jaspitest:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=datasources/jdbc-driver=h2:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=deployment-scanner/scanner=default:write-attribute(name=scan-interval,value=0)'

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=deployment-scanner/scanner=default:write-attribute(name=deployment-timeout,value=300)'

/opt/wildfly/bin/jboss-cli.sh --connect '/core-service=management/management-interface=http-interface:write-attribute(name=console-enabled,value=false)'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/subsystem=undertow/server=default-server/http-listener=http/:write-attribute(name=max-post-size,value=25485760)'
/opt/wildfly/bin/jboss-cli.sh --connect ':reload'
wildfly_check

/opt/wildfly/bin/jboss-cli.sh --connect '/core-service=management/access=audit/logger=audit-log:write-attribute(name=enabled,value=true)'

/opt/wildfly/bin/jboss-cli.sh --connect ':take-snapshot'

systemctl enable wildfly
