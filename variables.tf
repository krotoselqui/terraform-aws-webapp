variable "key_pair_name" {
    description = "Name of the key pair used for EC2 instance SSH access. The private key file (terraform-webapp.pem) should be in the project directory."
    type = string
    default = "terraform-webapp"
}

variable "bucket_prefix" {
    description = "Prefix for the S3 bucket name. A random suffix will be appended to ensure uniqueness."
    type = string
    default = "terraform-webapp-bucket"
}