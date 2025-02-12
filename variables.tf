variable "key_pair_name" {
    description = "Name of the key pair used for EC2 instance SSH access. The private key file (terraform-webapp.pem) should be in the project directory."
    type = string
    default = "terraform-webapp"
}