#!/bin/bash

set -x

namespace=system-design
component=${1}
route53_zone_fqdn=$(cat tmp/create-hosted-zone.out | jq -r '.HostedZone.Name' | rev | cut -c2- | rev)
route53_zone_id=$(cat tmp/create-hosted-zone.out | jq -r '.HostedZone.Id')
cluster_name=$(terraform -chdir=terraform output -raw cluster_name)
tls_secret_name=system-design-${component}-tls
profile=$(terraform -chdir=terraform output -raw aws_profile)

CERTIFICATE_ARN=$(aws acm list-certificates \
    --profile "$profile" \
    --query CertificateSummaryList[].[CertificateArn,DomainName] \
    --output text | grep "${component}.${route53_zone_fqdn}" | cut -f1 | head -n 1)

aws acm delete-certificate \
  --profile "$profile" \
  --certificate-arn "$CERTIFICATE_ARN"
