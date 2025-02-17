
.PHONY: requirements upgrade pin-pip

upgrade: ## update the pip requirements files to use the latest releases satisfying our constraints
	pip install -qr requirements/pip-tools.txt
	pip-compile --upgrade -o requirements/pip-tools.txt requirements/pip-tools.in
	pip-compile --upgrade -o requirements/base.txt requirements/base.in
	# Post process all of the files generated above to replace the instructions for recreating them
	script/post-pip-compile.sh \
        requirements/pip-tools.txt \
        requirements/base.txt

pin-pip:
	pip install -qr requirements/pip.txt

requirements: pin-pip
	pip install --no-cache-dir -q -r requirements/base.txt

# Run ansible with --connection local but WITHOUT -i 'localhost,' so that it
# runs the emr module in the local python which is likely necessary since that
# is where the proper version of boto is installed.
provision.emr: requirements
	ansible-playbook --connection local batch/provision.yml -e "$$EXTRA_VARS"

terminate.emr: requirements
	ansible-playbook --connection local batch/terminate.yml -e "$$EXTRA_VARS"

inventory.refresh:
	./plugins/ec2.py --refresh-cache >/dev/null

users.update: requirements inventory.refresh
	ansible-playbook -u "$$REMOTE_USER" infrastructure/users.yml -e "$$EXTRA_VARS"
