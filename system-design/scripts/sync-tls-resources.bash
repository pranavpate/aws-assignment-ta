#!/bin/bash -eu -o pipefail

set -x

namespace=system-design
component=${1}
route53_zone_fqdn=$(cat tmp/create-hosted-zone.out | jq -r '.HostedZone.Name' | rev | cut -c2- | rev)
route53_zone_id=$(cat tmp/create-hosted-zone.out | jq -r '.HostedZone.Id')
cluster_name=$(terraform -chdir=terraform output -raw cluster_name)
tls_secret_name=system-design-${component}-tls
profile=$(terraform -chdir=terraform output -raw aws_profile)

kubectl get secret $tls_secret_name -o json -n $namespace | \
   jq -r '.data."tls.crt"' | \
   base64 -d | \
   sed -e '/-----END CERTIFICATE-----/q' > tmp/certificate-${component}.pem

kubectl get secret $tls_secret_name -o json -n $namespace | \
   jq -r '.data."tls.crt"' | \
   base64 -d > tmp/certificate-chain-${component}.pem

kubectl get secret $tls_secret_name -o json -n $namespace | \
   jq -r '.data."tls.key"' | \
   base64 -d > tmp/private-key-${component}.pem

aws acm import-certificate \
  --profile "$profile" \
  --certificate fileb://$(pwd)/tmp/certificate-${component}.pem \
  --certificate-chain fileb://$(pwd)/tmp/certificate-chain-${component}.pem \
  --private-key fileb://$(pwd)/tmp/private-key-${component}.pem

CERTIFICATE_ARN=$(aws acm list-certificates \
    --profile "$profile" \
    --query CertificateSummaryList[].[CertificateArn,DomainName] \
    --output text | grep "${component}.${route53_zone_fqdn}" | cut -f1 | head -n 1)

kubectl annotate --overwrite ingress system-design-${component} \
    -n system-design \
    alb.ingress.kubernetes.io/certificate-arn=$CERTIFICATE_ARN
