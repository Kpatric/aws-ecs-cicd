#set provider for aws
provider "aws" {
  region = "us-east-2"
}

#create ecs fargate cluster
resource "aws_ecs_cluster" "payments_cluster" {
  name = "payments-cluster"
}

#create a task definition
resource "aws_ecs_task_definition" "location_service_task" {
  family                   = "location-service-task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "payments-container",
      "image": "${data.aws_ecr_repository.location_service_repo.repository_url}:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080,
          "protocol": "tcp"
        }
      ],
      "memory": 512,
      "cpu": 256,
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "location-service-log-group",
          "awslogs-region": "us-east-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }

  ]
DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::492749283155:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::492749283155:role/ecsTaskExecutionRole"
}

# Get the ECR repository URL
data "aws_ecr_repository" "location_service_repo" {
  name = "location-service-repo"
}

# Create an ECS Fargate service
resource "aws_ecs_service" "location_service" {
  name            = "location-service"
  cluster         = aws_ecs_cluster.payments_cluster.id
  task_definition = aws_ecs_task_definition.location_service_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  # Create a security group for the task
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }
  # Configure the service's load balancer to route traffic to the container
  load_balancer {
    target_group_arn = aws_lb_target_group.location_service_target_group.arn
    container_name   = "payments-container"
    container_port   = 8080
  }
  depends_on = [
    aws_alb_listener.location_service_listener,
    aws_lb_target_group.location_service_target_group
  ]
}

#create alb
resource "aws_alb" "location_service_alb" {
  name               = "location-service-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
}

resource "aws_alb_listener" "location_service_listener" {
  load_balancer_arn = aws_alb.location_service_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.location_service_target_group.arn
  }
}
# Create a target group for the load balancer
resource "aws_lb_target_group" "location_service_target_group" {
  name        = "location-service-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}





