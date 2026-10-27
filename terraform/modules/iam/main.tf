# Read the TLS certificate chain for the EKS OIDC issuer.
# Its root certificate thumbprint is used by the IAM OIDC provider.
data "tls_certificate" "eks" {
  url = var.oidc_issuer_url
}

# Register the EKS OIDC issuer with IAM for workload identity.
resource "aws_iam_openid_connect_provider" "eks" {
  url = var.oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks.certificates[0].sha1_fingerprint
  ]

  tags = var.tags
}

# Trust only the configured Kubernetes service account.
data "aws_iam_policy_document" "workload_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${var.kubernetes_namespace}:${var.service_account_name}"
      ]
    }
  }
}

# Create the IAM role assumed by the trusted application service account.
resource "aws_iam_role" "bagisto_workload" {
  name               = "bagisto-workload-s3-access"
  assume_role_policy = data.aws_iam_policy_document.workload_trust.json

  tags = var.tags
}

# Grant read and write access only to objects in the designated media bucket.
data "aws_iam_policy_document" "media_access" {
  statement {
    sid       = "ListMediaBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.media_bucket_arn]
  }

  statement {
    sid    = "ManageMediaObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = ["${var.media_bucket_arn}/*"]
  }
}

# Attach the narrowly scoped S3 permissions to the workload role.
resource "aws_iam_role_policy" "media_access" {
  name   = "bagisto-media-bucket-access"
  role   = aws_iam_role.bagisto_workload.id
  policy = data.aws_iam_policy_document.media_access.json
}
