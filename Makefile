
TF_SPARK_DIR=$(PWD)/terraform/spark-cluster
MASTER_IP=`head -n 1 terraform/.master-ip`

setup-terraform:
	cd $(TF_SPARK_DIR) && terraform init

setup-ansible:
	cd ansible && pipenv install
	cd ansible && pipenv run ansible-galaxy install -r roles.yml

setup: setup-terraform setup-ansible

link-config:
	ln -sf $(PWD)/config/*.auto.tfvars $(TF_SPARK_DIR)
	ln -sf $(PWD)/config/*.yml $(PWD)/ansible/group_vars/all

create: link-config
	cd $(TF_SPARK_DIR) && terraform apply
	cd ansible && pipenv run ansible-playbook deploy.yml

login:
	ssh ubuntu@$(MASTER_IP)

destroy:
	cd $(TF_SPARK_DIR) && terraform destroy
