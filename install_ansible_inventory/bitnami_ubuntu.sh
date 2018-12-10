#!/bin/bash
set -x

apt-get install -y ansible  python-pip git 
pip install ansible boto

# install inventory
cd /tmp
git clone https://github.com/ansible/ansible.git
mkdir -p /opt/ansible/inventory
cp /tmp/ansible/contrib/inventory/ec2*  /opt/ansible/inventory
chmod +x /opt/ansible/inventory/ec2.py
cd ansible
pip install -r requirements.txt

## keep in mind you need to set env variables 
# or use role for ec2 instance

#echo "export AWS_ACCESS_KEY_ID=KEY" >>  ~/.bashrc
#echo "export AWS_SECRET_ACCESS_KEY=SECRET" >>  ~/.bashrc
echo "export EC2_INI_PATH=/opt/ansible/inventory/ec2.ini" >> ~/.bashrc
echo "export ANSIBLE_INVENTORY=/opt/ansible/inventory/ec2.py" >> ~/.bashrc

# Put Pem KEY
cat <<EOF > /home/bitnami/.ssh/ssh-key.pem
-----BEGIN RSA PRIVATE KEY-----
YOUR KEY
-----END RSA PRIVATE KEY-----
EOF

chown bitnami:bitnami /home/bitnami/.ssh/ssh-key.pem
chmod 400 /home/bitnami/.ssh/ssh-key.pem

# Ansible config
mkdir /opt/ansible/update_code/
cat <<EOF > /opt/ansible/update_code/ansible.cfg
[defaults]
inventory=/opt/ansible/inventory/
host_key_checking = False
roles_path = roles
accelerate_timeout = 300
accelerate_connect_timeout = 60
timeout = 60
private_key_file = /home/bitnami/.ssh/ssh-key.pem
EOF

# EC2 INI
cat <<EOF > /opt/ansible/inventory/ec2.ini
[ec2]
regions = us-east-1,us-west-2
regions_exclude =
destination_variable = private_ip_address
vpc_destination_variable = private_ip_address
route53 = False
rds = False
elasticache = False
all_instances = False
#instance_states = pending, running, shutting-down, terminated, stopping, stopped
all_rds_instances = False
all_elasticache_replication_groups = False
all_elasticache_clusters = False
all_elasticache_nodes = False
cache_path = ~/.ansible/tmp
cache_max_age = 300
nested_groups = False
replace_dash_in_groups = True
expand_csv_tags = False
group_by_instance_id = True
group_by_region = True
group_by_availability_zone = True
group_by_ami_id = True
group_by_instance_type = True
group_by_key_pair = True
group_by_vpc_id = True
group_by_security_group = True
group_by_tag_keys = True
group_by_tag_none = True
group_by_route53_names = True
#pattern_include = staging-*
#pattern_exclude = staging-*
#instance_filters = instance-type=t1.micro,tag:env=staging
#only process items we tagged
EOF

# check that everything work
cd /opt/ansible/update_code
/opt/ansible/inventory/ec2.py --list 
ansible all -m ping -u ec2-user

# Set Ability for grab code from CodeCommit
sudo apt-get install -y python-pip 
sudo pip install awscli
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

