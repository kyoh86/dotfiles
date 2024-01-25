# AWS EC2のヘルパー

aws-ec2-search() {
  aws ec2 describe-instances --query 'Reservations[].Instances[?Tags[?Key==`Name`].Value|[0]==`'"$1"'`][]|[0].InstanceId' --output text
}
