variable "public_key_path" {
  default     = "~/.ssh/id_rsa.pub"
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default     = "tfkeypair"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "List of availability zones within aws_region"
  default     = "us-west-2a,us-west-2b,us-west-2c"
}

variable "aws_amis" {
  type = "map"
  default = {
    eu-west-1 = "ami-7abd0209"
    us-east-1 = "ami-6d1c2007"
    us-west-1 = "ami-af4333cf"
    us-west-2 = "ami-d2c924b2"
  }
}

variable "node_repo_url" {
  description = "The repository to clone when launching the Node cluster"
  default     = "https://github.com/cloudsoft/todo-mvc.git"
}

variable "node_app_filename" {
  description = "The root Node application file",
  default     = "app.js"
}

variable "database_creation_script" {
  description = "Used to initialise the database",
  default     = "https://raw.githubusercontent.com/cloudsoft/todo-mvc/master/server/db-creation-script.sql"
}
