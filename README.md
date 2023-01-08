Hello all,

**Infrastructure as a code** or simply **IaC** is a way of creating your infrastructure via code. Adwantages of using IaC are **fast** and **less time consuming**,and by using version control tools such as git you can setup the versioning too.

In this example we are configuring the setup with **Terraform** and **AWS provider**.Terraform is a well known and globaly used IaC tool for creating and managing infrastructure.

We can move to our project and the following diagram shows a sample representation of the whole setup.

![final-picture](https://user-images.githubusercontent.com/61390678/210266165-3c609d43-6cc4-4227-9a29-35cb80fc9909.png)

Let’s talk more about based on the above representation which will be easy to understand.Before that we can have a look on the variables that we have used in our code.

|Variable|Description                                              
| --- | --- |
|project|project name |                                         
|environment|project environment |                                    
|region|your aws region |                                              
| access_key | access key of IAM user |                                  
| secret_key | secret key of IAM user |                                  
| instance_ami | AMI for instances launched |                            
| instance_type  |type of instaces launched |                            
| vpc_cidr  | CIDR block which the VPC will use |                       
| private-domain  | private domain which used as the database host |     
| domain | domain which you need to install wordpress |                  
| database | database name of your wordpress site|                       
| database-user | database user for the wordpress |                      
| database-password | password of your database  |                       
|root-password  |password of root user in your mysql server |                   
|iplist |list of IPs which have ssh access to your bastion server |          
|ports-front |ports defined  for creating security group for webserver | 
|ssh-outside |condition check,If it is set as true you can access the bastion server from anywhere | |
|ssh-backend-pub|condition check,If it is set as true you can access the database server from anywhre within the VPC,by default ssh access is only from bastion server| 
|db-port   |port for databse service  |                                   
|bastion-port|ssh port for backend server |                              
|enable_nat_gateway|condtion check,if it is set as true a NAT gateway will be launched for pulic subnets | 

We are setting the the whole VPC setup with as a **module** which consits of a VPC, IGW,NAT, public and private subnets and it's associations.You only need to pass the
values to variables such as "project" , "environment" , "CIDR block" etc.

We are creating a VPC with CIDR **172.16.0.0/16** and hosting a multi-tire Wordpress website in this example. Within the VPC, 3 private and 3 public subnets are created. The subnets are created using the function **cidrsubnet**.You don't need to manually setup the subnets, the code will automatically create the subnets basesd on the no of availability zones in the region,and by default they are subnetted at **/20**. For enabling public IP to the instances launched in the public subnet, we are setting up the **map_public_ip_on_launch** value as **true**.

Also we are setting up a few **outputs** of vpc-module such as VPC id,NATGW id, public and private subnets ids for later use such as deploying  instances whithin the VPC and the security group associations.

We keep our **webserver/front-end** in a *public* subnet and our **database/backend** server in a different *private* subnet within the VPC. And ssh access to these resources is only enabled from the **bastion** server and it is also located in a different *public* subnet within the VPC. Internet access to the whole VPC is through **IGW** and **NATGW**. Internet access to private subnets is enabled via the NAT gateway.

We are setting the **NAT gateway** as a optional feature which used for internet traffic in the priavte subnets. If you don't need a NAT gateway in your infra you can set the variable **enable_nat_gateway** as **false**. If you set the value to false the **elastic IP**(EIP), which required for the NAT gateway won't be created and your infra will be launched without a NAT gateway, still the private subnets will be associated with the private route table.By default the value of enable_nat_gateway is set to **true**.The condition based decision making is done with help of **count** option.

3 instances are launched for our VPC, named as frontend,bastion,backend using the resource **aws_instance**. In the frontend server, we are enabling HTTP, SSH, and HTTPS traffic to the server via a security group attached to the instance. In the same way, MYSQL and SSH access are enabled for the backed/DB server. All the instances are using the AMI of amazon linux. As already mentioned ssh access is only from the bastion server and the bastion server is accessible from everywhere. It is not recommended in the production environment. If you are having a static IP you can add the IP address in the security group for better security.

One thing to notice here that you will get internet access to instances created in private subnet only after **NAT gateway** is created.When terraform creates the infra as per the code we have created NAT gateway lauches at the last point. So when the backend instance tried to run the userdata it will be ended up in nothing. because the instance doesn't have internet access and it can't download and instal MYSQL package and do the rest things.Here comes the role of dependency.When we configure the  backend instance we are adding a dependency on NAT gateway using the **depends_on** argument.So the backend instance will only create after the NAT gateway is up and running.

All in instances in the VPC are connected via a generated keypair. the Keypair is generated using ssh-keygen and it is saved in the working directory as mykey and mykey.pub

The generated keys are attached to the resource **aws_key_pair** via the **file** option.

Also, we are using 2 **route 53** zones within our VPC. The private zone is set up to resolve the connection between the database server and the front-end server. Please note that DNS records in the private subnet are only resolved within the VPC. The already existing public zone is used to set up the domain URL and it is accessed via the **data source**.

2 route tables created for the VPC. **rtb-public** and **rtb-private**. All the public subnets are associated with the rtb-public and private subnets are connected to rtb-private.We have 3 security groups created for the instances. backed, bastion and front-end.The inbound rules to the security groups are done with the **dynamic ingress** option which will reduce the code length. The ports are specified via variables.

Here the whole terraform code is splitted into 6 .tf files and you need to configure the **provider.tf** with your access key and secret key which is passed via variables.You can change values in the **variables.tf** file as per your requirement and change the default value to your required ones . we are using a few variables for our code than hardcoding the direct values so it would helpful while reusing the code for creating a different infra.Also we are using the locals options to pass a few values.

We are using 2 bash scripts as userdata for the front-end server and dbserver named as **mysql.sh** and **frontend.sh** correspondingly.And userdatas are attached to the instance with the attribute value **user_data**.The userdatas are passed to the instances as a **template file**.The adwantage of using a template is that you can pass the values to the variables mentioned in the userdata without editing the userdata, you only need to update values of variables mentioned in the template file. 

Regarding the userdata, while executing the ‘frontend.sh’ userdata PHP and apache packages will be installed. Since Wordpress required the latest php version we are installing it with help of amazon-linux install.Once these packages are installed the script will download the latest version of Wordpress via wget and will extract the Wordpress files to /var/ww/html and setting up the required permissions and ownmership.Once this configured we need to setup the wp-config file.Since we are using the database in a different server from a different subnet, we have to configure the db host too. instead of localhost.We are setting the value of db host as db.local and it is resolvable in the VPC. and other values are passed and variables and they are replaced in the wp-config.php file via sed command.

In the backed userdata, ie, ‘mysql.sh’ in this example, we are installing mariadb-server package and creating database and database user.We are passing the database and username as variables so that you can easily modified them if required, by changing the values in the variables.

Once you apply the code in terraform console Wordpress will be configured automatically and you only need to complete the installation by setting up a user name and password.

You will get a wordpress installation page as follows.

![wp](https://user-images.githubusercontent.com/61390678/211187067-88859788-a5a9-438d-99f4-a2455777b913.png)


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
$cd multi-tier-wordpress-deployment-with-terraform
$terraform init
$terraform validate
$terraform plan 
$terraform apply 
```
