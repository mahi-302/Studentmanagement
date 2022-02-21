pipeline{
  agent {label "main"}
    stages{
       stage("hosting application"){
        steps{
          sh "ls"
          sh "aws rds create-db-instance --db-instance-identifier test-mysql-final2 --db-name detsdb --db-instance-class db.t2.micro --vpc-security-group-ids  sg-0bb5391635b3c304e --engine mysql --engine-version 5.7 --db-parameter-group-name default.mysql5.7 --publicly-accessible  --master-username admin --master-user-password Ramrebel56 --allocated-storage 10 --region us-east-2"
          sleep(450)
          script{
              def cmd = "aws rds describe-db-instances --db-instance-identifier test-mysql-final2 --region us-east-2"
              def output = sh(script: cmd,returnStdout: true)
              jsonitem = readJSON text: output
              println(jsonitem)
           }
           sh "sed -i.bak 's/endpoint/${jsonitem['DBInstances'][0]['Endpoint']['Address']}/g' userdata.txt"
          script{
              def cmd = "aws elbv2 create-load-balancer --name my-load-balancer-final2 --subnets subnet-09521af8c6cfe39fb subnet-0080182dff1d4159a --security-groups sg-0bb5391635b3c304e --region us-east-2 "
              def output = sh(script: cmd,returnStdout: true)
              jsonitem1 = readJSON text: output
              println(jsonitem1)
              sleep(100)
            }
          script{
              def cmd = "aws elbv2 create-target-group --name my-target-final2 --protocol HTTP --port 80 --target-type instance --vpc-idvpc-0f607673eab7d2eb7 --region us-east-2"
              def output = sh(script: cmd,returnStdout: true)
              jsonitem2 = readJSON text: output
              println(jsonitem2)
              sleep(180)
               }
           sh "aws elbv2 create-listener --load-balancer-arn ${jsonitem1['LoadBalancers'][0]['LoadBalancerArn']} --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=${jsonitem2['TargetGroups'][0]['TargetGroupArn']} --region us-east-2"
           sh "aws autoscaling create-launch-configuration --launch-configuration-name my-lc2-final1 --image-id ami-0629230e074c580f2 --instance-type t2.micro --security-groups sg-0bb5391635b3c304e --key-name jenkins --iam-instance-profile ram-s3-role --user-data file://userdata.txt --region us-east-2"
           sh "aws autoscaling create-auto-scaling-group --auto-scaling-group-name my-asg3-final1 --launch-configuration-name my-lc2-final1 --max-size 2 --min-size 1 --desired-capacity 1 --target-group-arns ${jsonitem2['TargetGroups'][0]['TargetGroupArn']} --availability-zones us-east-2b --region us-east-2"
           sh "aws autoscaling create-auto-scaling-group --auto-scaling-group-name my-asg4-final1 --launch-configuration-name my-lc2-final1 --max-size 2 --min-size 1 --desired-capacity 1 --target-group-arns ${jsonitem2['TargetGroups'][0]['TargetGroupArn']} --availability-zones us-east-2b --region us-east-2"
           sh "aws autoscaling put-scaling-policy --auto-scaling-group-name my-asg3-final1 --policy-name alb1000-target-tracking-scaling-policy --policy-type TargetTrackingScaling --target-tracking-configuration file://config.json --region us-east-2"
           sh "aws autoscaling put-scaling-policy --auto-scaling-group-name my-asg4-final1 --policy-name alb1000-target-tracking-scaling-policy --policy-type TargetTrackingScaling --target-tracking-configuration file://config.json --region us-east-2"
        }
       }
  }
}
