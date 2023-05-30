module "app_runner_shared" {
  source  = "terraform-aws-modules/app-runner/aws"
  version = "1.2.0"

  create_service = false
  auto_scaling_configurations = {
    "scaling-config" = {
      name            = "scaling-config"
      max_concurrency = 10
      max_size        = 10
      min_size        = 1
    }
  }
}

module "app_runner_test_instance" {
  source  = "terraform-aws-modules/app-runner/aws"
  version = "1.2.0"

  create_service = false
  service_name   = "app-runner-scale-test"

  auto_scaling_configuration_arn = module.app_runner_shared.auto_scaling_configurations["scaling-config"].arn

  instance_configuration = {
    cpu    = 1024
    memory = 2048
  }

  source_configuration = {
    auto_deployments_enabled = true
    authentication_configuration = {
      access_role_arn = module.oidc.iam_role_arn
    }
    image_repository = {
      image_configuration = {
        port = 8080
      }
      image_identifier      = "${module.ecr.repository_url}/aws-app-runner-scale-test:1"
      image_repository_type = "ECR"
    }

  }

  create_vpc_connector               = false
  enable_observability_configuration = true
}

module "oidc" {
  source  = "unfunco/oidc-github/aws"
  version = "1.3.1"

  iam_role_name        = "ecr-access-role"
  github_repositories  = ["Antvirf/aws-app-runner-scale-test"]
  iam_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]


}

// create user and grant it the ecr-access-role
resource "aws_iam_user" "ecr-user" {
  name = "ecr-user"
}


resource "aws_iam_user_policy_attachment" "ecr-user-attachment" {
  user       = aws_iam_user.ecr-user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_access_key" "ecr-user-key" {
  user = aws_iam_user.ecr-user.name
}

output "ecr-user-access-key" {
  value = aws_iam_access_key.ecr-user-key.id
}

output "ecr-user-secret-key" {
  value     = aws_iam_access_key.ecr-user-key.secret
  sensitive = true
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_name = "test-ecr"
  repository_read_write_access_arns = [
    module.oidc.iam_role_arn
  ]

  repository_image_tag_mutability = "MUTABLE"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 2 images",
        selection = {
          countNumber = 2
          countType   = "imageCountMoreThan",
          tagStatus   = "any",
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}


