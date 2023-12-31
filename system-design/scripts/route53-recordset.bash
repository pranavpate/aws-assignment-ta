#!/bin/bash -eu -o pipefail

set -euxo pipefail

namespace=system-design
action=${1:-CREATE}
component=${2}
route53_zone_fqdn=$(cat tmp/create-hosted-zone.out | jq -r '.HostedZone.Name' | rev | cut -c2- | rev)
route53_zone_id=$(cat tmp/create-hosted-zone.out | jq -r '.HostedZone.Id')
cluster_name=$(terraform -chdir=terraform output -raw cluster_name)
profile=$(terraform -chdir=terraform output -raw aws_profile)

lb_hostname=$(kubectl get ingress -n system-design system-design-${component} -o json | \
    jq -r '.status.loadBalancer.ingress[0].hostname')

cat > tmp/change-batch-${component}.${route53_zone_fqdn} <<EOF
{
  "Comment": "${action^^} CNAME for ${component}.${route53_zone_fqdn}",
  "Changes": [{
      "Action": "${action^^}",
      "ResourceRecordSet": {
          "Name": "${component}.${route53_zone_fqdn}",
          "Type": "CNAME",
          "TTL": 300,
          "ResourceRecords": [{ "Value": "$lb_hostname" }]
      }
  }]
}
EOF

aws route53 change-resource-record-sets \
    --hosted-zone-id "$route53_zone_id" \
    --change-batch file://$(pwd)/tmp/change-batch-${component}.${route53_zone_fqdn}
