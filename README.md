Hello all,

**Infrastructure as a code** or simply **IaC** is a way of creating your infrastructure via code. Adwantages of using IaC are **fast** and **less time consuming**,and by using version control tools such as git you can setup the versioning too.

In this example we are configuring the setup with **terraform** and **AWS provider**.Terraform is a well known and globaly used IaC tool for creating and managing infra.

We can move to our project and the following diagram shows a sample representation of the whole setup.

![final-picture](https://user-images.githubusercontent.com/61390678/210266165-3c609d43-6cc4-4227-9a29-35cb80fc9909.png)

Let’s talk more about based on the above picture which will be easy to understand.

We are creating a VPC with CIDR **172.16.0.0/16** and hosting a multi- tire Wordpress website in this example. Within the VPC, 3 private and 3 public subnets are created. The subnets are subnetted at **/20**. The subnets are created using the function **cidrsubnet**.For enabling public IP to the instances launched in the public subnet we are setting up the map_public_ip_on_launch value as **true**.

We keep our web server/front end in a public subnet and our database/backend server in a different public subnet within the VPC. And ssh access to these resources is only enabled from the bastion server and it is also located in a separate public subnet within the VPC. Internet access to the whole VPC is through **IGW** and **NATGW**. Internet access to private subnets is enabled via a NAT gateway.

3 instances are launched for our VPC, named as frontend,bastion,backend using the resource **aws_instance**. In the frontend server, we are enabling HTTP, SSH, and HTTPS traffic to the server via a security group attached to the instance. In the same way, MYSQL and SSH access are enabled for the backed/DB server. All the instances are using the AMI of amazon linux. As already mentioned ssh access is only from the bastion server and the bastion server is accessible from everywhere. It is not recommended in the production environment. If you are having a static IP you can add the IP address in the security group for better security.

One thing to notice here that you will get internet access to instances created in private subnet only after **NAT gateway** is created.When terraform creates the infra as per the code we have created NAT gateway lauches at the last point. So when the backend instance tried to run the userdata it will be ended up in nothing. because the instance doesn't have internet access and it can't download and instal MYSQL and do the rest things.Here comes the role of dependency.When we configure the  backend instance we are adding a dependency on NAT gateway using the **depends_on** argument.So the backend instance will only create after the NAT gateway is up and running.

All in instances in the VPC are connected via a generated keypair. the Keypair is generated using ssh-keygen and it is saved in the working directory as mykey and mykey.pub
The generated keys are attached to the resource **aws_key_pair** via the **file** option.

Also, we are using 2 **route 53** zones within our VPC. The private zone is set up to resolve the connection between the database server and the front-end server. Please note that DNS records in the private subnet are only resolved within the VPC. The already existing public zone is used to set up the domain URL and it is accessed via the data source.

In order to enable internet traffic to the private subnets, we are launching a NAT gateway, and to set up the NAT gateway you have to purchase an EIP (elastic IP address).

2 route tables created for the VPC. **rtb-public** and **rtb-private**. All the public subnets are associated with the rtb-public and private subnets are connected to rtb-private.We have 3 security groups created for the instances. backed, bastion and front-end.

Here the whole terraform code is splitted into 6 .tf files and you need to configure the **provider.tf** with your access key and secret key which is passed via variables.You can change values in the **variables.tf** file as per your requirement and change the default value to your required ones . we are using a few variables for our code than hardcoding the direct values so it would helpful while reusing the code for creating a different infra.Also we are using the locals options to pass a few values.

We are using 2 bash scripts as userdata for the front-end server and dbserver named as **mysql.sh** and **frontend.sh** correspondingly.and userdatas are attached to the instance with the attribute value **user_data**.While executing the ‘frontend.sh’ userdata PHP and apache packages will be installed. Since Wordpress required the latest php version we are installing it with help of amazon-linux install.Once these packages are installed the script will download the latest version of Wordpress via wget and will extract the Wordpress files to /var/ww/html and setting up the required permissions and ownmership.Once this configured we need to setup the wp-config file.Since we are using the database in a different server from a different subnet, we have to configure the db host too. instead of localhost.We are setting the value of db host as db.local and it is resolvable in the VPC. and other values are passed and variables and they are replaced in the wp-config.php file via sed command.

In the backed userdata, ie, ‘mysql.sh’ in this example, we are installing mariadb-server package and creating database and database user.We are passing the database and username as variables so that you can easily modified them if required by changing the values in the variables.

Once you apply the code in terraform console Wordpress will be configured automatically and you only need to complete the installation by setting up a user name and password.

Please have a look and if you need any clarification please let me know, also suggestions are invited :)

Prerequisite

- IAM user with programmatic access and AmazonEc2FullAccess and AmazonRoute53FullAccess
- machine with  latest version of git and terraform installed

 Use git clone to download the project files to your local system for execution
```
git clone https://github.com/antony-a-n/multi-tier-wordpress-deployment-with-terraform.git
```
run the following commands
```
cd multi-tier-wordpress-deployment-with-terraform
terraform init
terraform validate
terraform plan 
terraform apply 
```
