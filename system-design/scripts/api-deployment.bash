#!/bin/bash

set -exuo pipefail

component=api
action=${1:-apply}

cd apps/${component}

registry=$(terraform -chdir=../../terraform output -raw registry_${component})
route53_zone_fqdn=$(cat ../../tmp/create-hosted-zone.out | jq -r '.HostedZone.Name' | rev | cut -c2- | rev)
cluster_name=$(terraform -chdir=../../terraform output -raw cluster_name)
image_version="$(cat ../../tmp/latest-image-version-${component})"
db_endpoint=$(terraform -chdir=../../terraform output -raw db_endpoint)
db_name=$(terraform -chdir=../../terraform output -raw db_name)

cat ${component}.yaml | \
  sed 's@REGISTRY_URL@'"${registry}"'@' | \
  sed 's@ROUTE53_ZONE_FQDN@'"${route53_zone_fqdn}"'@' | \
  sed 's@CLUSTER_NAME@'"${cluster_name}"'@' | \
  sed 's@IMAGE_VERSION@'"${image_version}"'@' | \
  sed 's@DB_ENDPOINT@'"${db_endpoint}"'@' | \
  sed 's@DB_NAME@'"${db_name}"'@' | \
  kubectl ${action} -n system-design -f -
