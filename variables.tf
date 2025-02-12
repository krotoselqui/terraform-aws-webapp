variable "key_pair_name" {
    description = "Name of the key pair used for EC2 instance SSH access. The private key file (terraform-webapp.pem) should be in the project directory."
    type = string
    default = "terraform-webapp"
}

variable "bucket_name" {
    description = "Name of the S3 bucket to be created. Must be globally unique."
    type = string
    default = "terraform-webapp-bucket-${random_id.suffix.hex}"
}