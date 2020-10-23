#!/bin/bash

echo "SRE_TOOLING_SERVER_GROUP=\"${group}\"" >> /etc/default/sre-tooling
echo "SRE_TOOLING_REGION=\"${region}\"" >> /etc/default/sre-tooling

if [ "${run_mybatis_migrations}" == "true" ] ; then
  /opt/mybatis/mybatis-migrations-${mybatis_version}/bin/migrate up --path=/opt/opensrp/configs/assets/migrations --env=deployment
fi
