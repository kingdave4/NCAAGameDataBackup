resource "aws_ecr_repository" "my_ecr" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete = true
}
