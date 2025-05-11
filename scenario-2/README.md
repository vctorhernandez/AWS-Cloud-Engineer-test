# Scenario 2 –  APIs-as-a-Product Public and private APIs

## 1. What weaknesses can you see on the current architecture?

- Overexposed surface: Internal APIs are unnecessarily exposed to the internet.
- No internal/external segmentation: All traffic, even from internal apps, must pass through public routes (CloudFront → WAF → API GW).
- Single point of failure: One global endpoint (`api.allianz-trade.com`) introduces coupling between APIs and teams.
- Limited routing control: Path-based routing is needed but not fully leveraged.
- Risk of WAF bypass: Regional API Gateway endpoints are still publicly accessible and can be directly targeted.

## 2. We would like to change the exposition of these APIs. APIs intended for internal usage must go private, and APIs for both internal and external usage must be exposed internally and externally, hence, internal calls (from our network) must no longer go through internet -> cloudfront -> apigw -> backend service. What would the new architecture be, simple efficient and with the less impact possible?

#### Internal-only APIs:
- Deploy as Private API Gateways with Interface VPC Endpoints (via AWS PrivateLink).
- Internal applications resolve the private DNS (`vpce-*.execute-api.region.vpce.amazonaws.com`) and communicate over private VPC links.

#### Internal + External APIs:
- Keep using Regional API Gateways behind CloudFront for external access.
- For internal access, configure Route 53 Private Hosted Zones or use Transit Gateway/VPC Peering to allow direct calls to the API Gateway endpoint from internal systems.

#### Security Enhancements:
- Enforce IAM-based authorization or mTLS for internal consumers.
- Continue using Lambda authorizers or transition to Amazon Cognito for external users


## 3. In the current architecture how cloudfront could be configured to route traffic to multiple APIGWs based on path (path-based routing)? 

CloudFront allows defining cache behaviors that map URL path patterns to different origins (API Gateway endpoints):

Example Configuration:

- `/api/internal/*` → Origin A (internal API Gateway)
- `/api/public/*`   → Origin B (external API Gateway)
- `/api/broker/*`   → Origin C (partner API Gateway)


## 4. If we want to protect our regional APIGW endpoints (which are public) from traffic that “Bypass” the cloudfront/WAF and directly reach APIGW endpoints, what would you suggest as a solution?

Use an API Gateway resource policy to deny any invocation unless the request comes from trusted IPs (e.g., CloudFront, internal NAT gateways)

This ensures that even if someone knows the API Gateway endpoint URL, they cannot invoke it unless traffic is routed through approved sources (e.g., CloudFront, internal NAT IPs).

Example:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:<region>:<account_id>:<api_id>/*",
      "Condition": {
        "StringNotEquals": {
          "aws:SourceIp": [
            "<CloudFront IP ranges>",
            "<Internal NAT or VPN IPs>"
          ]
        }
      }
    }
  ]
}

