module "app_runner_shared" {
  source  = "terraform-aws-modules/app-runner/aws"
  version = "1.2.0"

  create_service = false
  auto_scaling_configurations = {
    "multi-instance" = {
      name            = "multi-instance"
      max_concurrency = 10
      max_size        = 5
      min_size        = 1
    }
    "single-instance" = {
      name            = "single-instance"
      max_concurrency = 10
      max_size        = 1
      min_size        = 1
    }
  }
}

module "app_runner_test_instance" {
  source  = "terraform-aws-modules/app-runner/aws"
  version = "1.2.0"

  create_service = true
  service_name   = "app-runner-scale-test"

  auto_scaling_configuration_arn = module.app_runner_shared.auto_scaling_configurations["multi-instance"].arn

  instance_configuration = {
    cpu    = 1024
    memory = 2048
  }

  source_configuration = {
    auto_deployments_enabled = true
    authentication_configuration = {
      access_role_arn = module.ecr_access_role.iam_role_arn
    }
    image_repository = {
      image_configuration = {
        port = 8080
      }
      image_identifier      = "${module.ecr.repository_url}:6"
      image_repository_type = "ECR"
    }
  }

  create_vpc_connector               = false
  enable_observability_configuration = true
}

module "ecr_access_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.1"

  role_name         = "ecr-access-role"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AWSAppRunnerFullAccess",
  ]

  trusted_role_services = [
    "tasks.apprunner.amazonaws.com",
    "build.apprunner.amazonaws.com",
  ]

  trusted_role_actions = [
    "sts:AssumeRole",
    "sts:TagSession",
    "sts:AssumeRoleWithWebIdentity",
  ]
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
    module.ecr_access_role.iam_role_arn,
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

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "app-runner-load-test-dashboard"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 6,
          "width" : 24,
          "y" : 0,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/AppRunner", "RequestLatency", "ServiceName", "app-runner-scale-test", "ServiceID", module.app_runner_test_instance.service_id, { "region" : "ap-southeast-1" }]
            ],
            "period" : 60,
            "region" : "ap-southeast-1",
            "stacked" : false,
            "stat" : "Average",
            "title" : "Request latency",
            "view" : "timeSeries"
          }
        },
        {
          "height" : 6,
          "width" : 24,
          "y" : 12,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/AppRunner", "Concurrency", "ServiceName", "app-runner-scale-test", "ServiceID", module.app_runner_test_instance.service_id, { "region" : "ap-southeast-1" }],
              [".", "ActiveInstances", ".", ".", ".", ".", { "region" : "ap-southeast-1", "yAxis" : "right" }]
            ],
            "period" : 60,
            "region" : "ap-southeast-1",
            "stacked" : false,
            "stat" : "Average",
            "view" : "timeSeries",
            "title" : "ActiveInstances, Concurrency"
          }
        },
        {
          "height" : 6,
          "width" : 24,
          "y" : 6,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/AppRunner", "Requests", "ServiceName", "app-runner-scale-test", "ServiceID", module.app_runner_test_instance.service_id, { "region" : "ap-southeast-1" }]
            ],
            "period" : 60,
            "region" : "ap-southeast-1",
            "stacked" : false,
            "stat" : "Average",
            "title" : "Requests",
            "view" : "timeSeries"
          }
        }
      ]
    }
  )
}
