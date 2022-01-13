# **Synchronized website on AWS hosting**
It's a simple personal static website (html + css) with instruments to run it on AWS EC2 service and monitore GPU usage and trace logs.

![](https://img.shields.io/github/last-commit/PavloPavlichenko/DockerTask) ![](https://img.shields.io/github/commit-activity/y/PavloPavlichenko/DockerTask)
# **Running and Testing Locally**
### Pre-reqs
- Be using Linux, WSL or MacOS with bash
- [Docker](https://docs.docker.com/engine/install/) or using [play-with-docker](https://labs.play-with-docker.com/) service - for running container, or image build and push
- [Terraform](https://www.terraform.io/intro) - for running code using IaC approach
- [Github actions](https://docs.github.com/en/actions/quickstart) - for building pipeline

Fork the project to your github account and then clone it

```
git clone https://github.com/yourlogin/yourreposname.git
```

Make git secrets and values for `github workflow`

| Variable          | Value                         |
| ----------------- | ----------------------------- |
| DOCKER_PASSWORD   | Your docker account password  |
| DOCKER_USERNAME   | Your docker account login     |

## Create first Docker image
Create repository on [dockerhub](https://hub.docker.com/)

Login to docker
```bash
echo "$DOCKER_PASSWORD" | docker login -u $DOCKER_USERNAME --password-stdin
```

Build image from Dockerfile in cloned repo
```bash
docker build . -t yourlogin/reponame:latest
```
Push created image to hub
```bash
docker push yourlogin/reponame:latest
```

## Configure AWS credentials
- Create user in IAM and provide AdministrationAccess permission policy
- Save users credentials (access key id and secret access key)
- Choose appropriate availability zone, e.g. `eu-north-1`
- Create key pair for instances creation/connection

Export credentials and zone (optional) in bash
```bash
export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="eu-north-1"
```

## Configure your main.tf file
Change region (optional)
```
provider "aws" {
    region = "eu-north-2" 
}
```
Change key pair and docker hub where image was saved and change time for watchtower to check for new images (optional) 
```
resource "aws_instance" "web"{
    ...
    iam_instance_profile   = aws_iam_instance_profile.logging_profile.name       // optional feature
    key_name               = "key-pair-name"
    ...
    user_date = 
    ...
    docker run -d -p 80:80 dockerlogin/reponame:latest
    docker run -d --name watchtower ... -i 10 // your time in seconds
    ...
}
```

Resources `aws_iam_role`, `aws_iam_policy_attachment`, `aws_iam_instance_profile` and `aws_cloudwatch_metric_alarm` are optional features

## Configure your github workflow
Change tag for builded image
```
 - name: Docker build
    
      run: |
        docker build . -t dockerlogin/reponame:latest
```
Push by renamed tag
```
 - name: Docker Push
    
      run: |
        docker push dockerlogin/reponame:latest
```
## Run app
Run terraform to create resources in aws
```bash
terraform apply
```
Go to EC2 instances page, copy public IP and paste into adress bar - you will see page with cv
## Change html and css
In www/ folder you can change `index.html` and `style.css` or create additional files

On pushing changes to main branch page should update in couple of seconds
## Creating custom DNS
- Create DNS on [Route53](https://aws.amazon.com/ru/route53/) in AWS or another site
- In Route53 create hosted zone with DNS name (if DNS made by Route53 - zone will be created automatically)
- Update NS on domain provider site with provided by AWS
- Add record that redirects from DNS name to public IP of your instance
# Optional Features
The following features could be enabled:

## Logging redirection to AWS cloudwatch
Add logging group in [AWS Cloudwatch](https://aws.amazon.com/cloudwatch/)

Change main.tf docker run by adding additional flags
```bash
docker run -d --log-driver=awslogs --log-opt awslogs-group=`group name` -p 80:80 dockerlogin/reponame:latest
```

Creating additional resources
```
// role to connect to ec2 instance
resource "aws_iam_role" "logging_role"{
    // inner code
}
// attaching policy to role
resource "aws_iam_policy_attachment" "logging_policy_role"{
    // inner code
}
// creating profile that would be connected to instance
resource "aws_iam_instance_profile" "logging_profile"{
    // inner code
}
```
Attach profile to instance
```
resource "aws_instance" "web"{
    ...
    iam_instance_profile   = aws_iam_instance_profile.logging_profile.name
    ...
}
```
Your logs would be saved in Cloudwatch -> Log Groups -> Group Name -> Needed stream

## CPU monitoring with CLoudwatch
You can monitor CPU usage and recieve notifications depending on conditions (for this one we are going to have a cloudwatch alarm metric that looks for average CPU to exceed 80% in 2 evaluation periods that last 120 seconds each)

Add cloudwatch metric alarm resource to main.tf
```
resource "aws_cloudwatch_metric_alarm" "ec2_cpu"{
    // inner code
}
```
More about configuring you can read in [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)

You can check for alarms in Cloudwatch -> Alarms