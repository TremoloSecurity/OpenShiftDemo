# OpenUnison on OpenShift IDaaS Demo

On February 25th we did a [presentation for the OpenShift Commons on OpenUnison and its capabilities](https://www.youtube.com/watch?v=E6UWEubjdno&feature=youtu.be).  This wiki page details
the steps we went through to build out the demo, including how we built out OpenShift.

## Architecture

![OpenShift IDaaS Architecture](https://www.tremolosecurity.com/docs/tremolosecurity-docs/images/openshift/openshift.png)

The idea behind the deployment was to show off OpenUnison's capabilities for both SSO and user provisioning.  We deployed two
applications inside of OpenShift:

1. An IDentity as a Service (IDaaS) built on OpenUnison and Scale
2. Wordpress with OpenUnison

The flow is:

1. A user authenticates to the IDaaS, against Active Directory
2. The IDaaS OpenUnison deployment runs a JIT provisioning workflow that pushes the user's objectGUID and samAccountName into a database
3. The virtual directory joins the data from the database table and the user's object in Active Directory in real-time
4. The user is logged into Scale

Once the user is logged into Scale, they can request access to applications where they'll be presented with links to the AWS Console and Wordpress based on their authorizations stored in the local database.

When the user clicks on the link to WordPress they get a SAML assertion with their identity attributes and WordPress authorizations.  The
WordPress OpenUnison then:

1. Updates the WordPress database with the correct permissions based on the assertion
2. Pre-authenticates the user to /wp-login.php to create the user's session
3. Stores the user's WordPress session cookies in OpenUnison's internal cookie jar
4. Generated the LastMile token to SSO the user into WordPress

To build out this demo we decided to deploy an NFS server and MySQL server external to OpenShift.  The NFS server is for storing the
configuration files for OpenUnison, Scale and WordPress.  The MySQL server stores the audit database used by OpenUnison, the authorization database used by OpenUnison and the database used by WordPress.

## OpenShift Deployment

Our first pass we tried to use the [All-In-One OpenShift Origin VM](https://www.openshift.org/vm/) but we ran into issues with trying to access our NFS server so we decided to try deploying OpenShift Origin onto our own.  After doing some research we decided to go with CentOS 7 instead of Atomic really only because we knew how to work with Docker and CentOS better.  

Once we made that decision the next choice we had was to either go with the downloading the Origin docker container or the "advanced" options.  We were able to get the docker image working quickly, but it appeared to just be the Origin webapp and services but it didn't seem to be a 1-1 with the all-in-one VM so we looked at following the "Advanced" instructions from the [Advanced Installation](https://docs.openshift.org/latest/install_config/install/index.html) section of the Origin documentation.

The deployment was really very easy at that point.  We ended up using the docker image based install versus using RPMs.  We ran into an issue with the RPM based install where the Ansible playbooks were looking for synmlinks that weren't there.  We ran the Ansible playbooks from a local CentOS 7 VM, first generating the an SSH key for root and deploying it to the OpenShift demo server.  

To get OpenShift up and running we:

1. Installed a CentOS 7 minimal install for the OpenShift host (openshift.tremolo.lan) and followed the directions on the [Prerequisites](https://docs.openshift.org/latest/install_config/install/prerequisites.html) site, specificly:
   1.  `yum install wget git net-tools bind-utils iptables-services bridge-utils bash-completion`
   2.  `yum update`
   3.  `yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm`
   4.  `sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo`
   5.  `systemctl stop firewalld`
   6.  `systemctl disable firewalld`
   5.  Installed Docker using [the instructions from Docker](https://docs.docker.com/engine/installation/linux/centos/)
2. We setup another CentOS 7 minimal install as the Ansible host and followed the directions on the [Prerequisites](https://docs.openshift.org/latest/install_config/install/prerequisites.html) site, specificly:
  1. `yum install wget git net-tools bind-utils iptables-services bridge-utils bash-completion`
  2. `yum update`
  3. `yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm`
  4. `sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo`
  5. `yum -y --enablerepo=epel install ansible pyOpenSSL`
  6. Generate an ssh key and add it to the /root/.ssh/authorized_keys file so root can SSH in without a password
  7. Cloned the openshift-ansible github repository
    1. `cd ~`
    2. `git clone https://github.com/openshift/openshift-ansible`
    3. `cd openshift-ansible`

Then we created the following /etc/ansible/hosts on the Ansible host system:

```
[OSEv3:children]
masters
nodes

[OSEv3:vars]
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]
osm_default_subdomain=apps.os.tremolo.lan
deployment_type=origin

[masters]
openshift.tremolo.lan containerized=true

[nodes]
openshift.tremolo.lan containerized=true openshift_scheduleable=true
```

The above hosts file will deploy OpenShift as both a master and node on a single server (openshift.tremolo.lan) using the docker images method instead of RPMs configuring OpenShift to use the generic HTPassword system from apache for authentication.  Finally, from the Ansible host we ran the playbook:

```bash
$ ansible-playbook /root/openshift-ansible/playbooks/byo/config.yml
```

If all goes well it will take a few minutes for OpenShift to setup and deploy.  Once the playbook was completed (maybe 10 minutes) we had to create the admin user.  While logged into the master:

```
$ htpasswd /etc/origin/master/htpasswd admin
.
.
.
$ oadm policy add-cluster-role-to-user cluster-admin admin
```  

At this point the admin user was able to login to OpenShift using both the website AND the command line tools remotely and we were ready to start deploying.


## Docker Repository

We just used a personal repository on dockerhub for images.  It would have been better to deploy a private repo and integrate it with OpenShift but given we were just doing a POC we decided to go the easier route.

## OpenUnison IDaaS

While OpenUnison has a docker image on dockerhub, it wouldn't work with OpenShift.  This is because OpenShift runs containers outside of root and any known user so the process that started didn't have access to the tomcat filesystem.  We didn't make /usr/local/tomcat world readable in our current image so for the sake of the demo we created a custom image just for OpenShift.  We'll be taking the lessons learned and building them into the OpenUnison and Scale base images on DockerHub shortly.

The same went for Scale, though once we had the OpenUnison image running getting Scale up and running took much less time.  The only tricky part we can into was getting the tomcat TLS listener available through a service (as Scale communicates with OpenUnison over a mutual authentication TLS connection).

## Wordpress OpenUnison

The OpenUnison for Wordpress was very easy to get up and running.  We just re-used the same image but mounted a different persistent volume for configuration.

## Wordpress

Getting wordpress running was extremely simple. We started with the standard Wordpress docker image and followed [the example in github used to show how persistent volumes work](https://github.com/openshift/origin/tree/master/examples/wordpress).  Once we had Wordpress working we had to enable the LastMile system between OpenUnison and Wordpress.  Do do this we created a custom image built off of the stock WordPress image but with the addition of the libraries needed to support mod_auth_tremolo and installation of the Apache module compiled on Ubuntu.  

Since users would be accessing wordpress through OpenUnison, we deployed wp (the wordpress CLI tool) to our NFS server so we can update wordpress with the correct host name for OpenUnison.  

Finally, we had to create a view in wordpress' database to support the OpenUnison database provisioning target.  OpenUnison doesn't know how to look at multiple tables for user data, so the following view pulls it all together:

```sql
CREATE VIEW `wp_unisonusers` AS
  select `wp_users`.`ID` AS `ID`,
  `wp_users`.`user_login` AS `user_login`,
  `wp_users`.`user_pass` AS `user_pass`,
  `wp_users`.`user_nicename` AS `user_nicename`,
  `wp_users`.`user_email` AS `user_email`,
  `wp_users`.`user_url` AS `user_url`,
  `wp_users`.`user_registered` AS `user_registered`,
  `wp_users`.`user_activation_key` AS `user_activation_key`,
  `wp_users`.`user_status` AS `user_status`,
  `wp_users`.`display_name` AS `display_name`,
  (select `wp_usermeta`.`meta_value` from `wp_usermeta` where ((`wp_usermeta`.`user_id` = `wp_users`.`ID`) and (`wp_usermeta`.`meta_key` = 'first_name'))) AS `first_name`,
  (select `wp_usermeta`.`meta_value` from `wp_usermeta` where ((`wp_usermeta`.`user_id` = `wp_users`.`ID`) and (`wp_usermeta`.`meta_key` = 'last_name'))) AS `last_name`,
  (select `wp_usermeta`.`meta_value` from `wp_usermeta` where ((`wp_usermeta`.`user_id` = `wp_users`.`ID`) and (`wp_usermeta`.`meta_key` = 'use_ssl'))) AS `use_ssl`
  from `wp_users`
```

## Lessons Learned

Other then learning how to build and deploy OpenShift, the biggest leasons learned were around how to build and design containers.  Making sure they're portable and work regardless if they're running on OpenShift or generic Docker.  

## Whats Next?

From here we're going to be updating our Docker images to run better in OpenShift.  We'll also be building a source-2-image system and template that will make it easier to deploy OpenUnison.  Not only will this make it easier to manage configurations but also adding customizations to OpenUnison in a Docker image.  We're also going to add better support for using the Kubernetes secret and config APIs for less reliance on persistent volumes for configuration.

## Tremolo Security
Useful links

* [Tremolo Security Home](https://www.tremolosecurity.com/)
* [Wiki Home](https://www.tremolosecurity.com/wiki/#!index.md)
* [Tremolo Security on Github](https://www.github.com/tremolosecurity/)
* Follow us on Twitter - [gimmick:twitterfollow](tremolosecurity) @tremolosecurity
