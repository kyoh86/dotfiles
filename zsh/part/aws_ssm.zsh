# AWS SSMのヘルパー

aws-ssm-session() {
  aws ssm start-session --target $1
}

aws-ssm-port-forwarding() {
  aws ssm start-session --target $1 --document-name AWS-StartPortForwardingSession --parameters "portNumber"=["$2"],"localPortNumber"=["$3"]
}
