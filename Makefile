.PHONY: infra
infra:
	@terraform -chdir=infrastructure init
	@terraform -chdir=infrastructure apply -var "vault_token=$(shell pass show vault/root-token)"

.PHONY: console
console:
	@ping -c1 -W1 terrarium >/dev/null
	@ssh -t -o StrictHostKeyChecking=no root@terrarium screen -d -r -S terraria
