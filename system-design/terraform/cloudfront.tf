resource "aws_cloudfront_distribution" "route53_distribution" {
  origin_group {
    origin_id = "groupRoute53"

    failover_criteria {
      status_codes = [403, 404, 500, 502]
    }

    member {
      origin_id = "primaryRoute53"
    }

    member {
      origin_id = "failoverRoute53"
    }
  }

  origin {
    domain_name = aws_route53.primary_regional_domain_name
    origin_id   = "primaryRoute53"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_route53.failover_regional_domain_name
    origin_id   = "failoverRoute53"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    # ... other configuration ...
    target_origin_id = "groupS3"
  }

  # ... other configuration ...
}