.PHONY: *

export AWS_ACCESS_KEY_ID=$(shell pass show aws/terraform-backend-access-key)
export AWS_SECRET_ACCESS_KEY=$(shell pass show aws/terraform-backend-secret-key)
export VAULT_TOKEN=$(shell pass show vault/root-token)

# A workaround while Terraform does not support the ap-southeast-4 region
# https://github.com/hashicorp/terraform/issues/30282
terraform := /Users/nchlswhttkr/Code/terraform/terraform

apply: init
	@$(terraform) apply

init:
	@$(terraform) init

destroy: init
	@$(terraform) destroy
