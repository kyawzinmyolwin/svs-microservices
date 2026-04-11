variable "environment" {
  description = "Environment label used in resource names and tags"
  type        = string
}

variable "services" {
  description = "List of microservice names — one ECR repo is created per service"
  type        = list(string)
  default = [
    "customer_service",
    "catalog_service",
    "appointments_service",
    "frontend_service"
  ]
}

variable "image_retention_count" {
  description = "Number of images to keep per repo — older ones are deleted automatically"
  type        = number
  default     = 5
}
