# S3 Backup Infrastructure

This is a partner repository for the [s3backup](https://github.com/studio1767/s3backup) project. It creates the 
infrastrucuture needed for that project including:

* AWS S3 bucket
* AWS IAM users with the necessary permissions and access keys
* Age encryption identities and recipients
* Passphrase secret files for the users
* Initial job template files for each user

The recipient file is also uploaded to the bucket ready for use.

## Prerequisites

There are a few tools that need to be installed and running before proceeding. They're all pretty
straight forward to setup - links to their installation documentation.

* [AWS Account](https://docs.aws.amazon.com/SetUp/latest/UserGuide/setup-overview.html)
* [A working AWS CLI](https://aws.amazon.com/cli/)
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* [Age encryption](https://github.com/FiloSottile/age)

## Quick Start

This walks though getting the system built and ready to go without much detail on the internals. There's more detail on
the encryption and configuration files in the main [s3backup](https://github.com/studio1767/s3backup) repository.

### Setup Variables

The configuration and build is driven by variables that you customize. Copy the file `terraform.tfvars.example`
to `terraform.tfvars` and edit the variables to match what you need.

This defines the aws credentials and region used to build the system, the name of the bucket to create, and the
users with admin, backup and restore permissions.

### Build The System

This is simple. If you've got your variables right, simply run:

    terraform init
    terraform apply

Once this is completed, the bucket is created and the recipients encryption key is uploaded to
the key `repo/recipients.txt` ready for the tools to use it.

### Distribute User Files

Under the `local` directory there is a folder called `users` which contains aws credentials and config files
for each user and the secrets.yml file with the passphrase secrets for encryption.

To install these files:

| File        | Instructions                                          |
|-------------|-------------------------------------------------------|
| config      | add the contents to the file ~/.aws/config            |
| credentials | add the contents to the file ~/.aws/config            |
| secrets.yml | create a directory ~/.s3bu and copy the file in there |

If the user is an admin or also needs to be able to restore content, you will also need to 
install the `identities.txt` file at `~/.s3bu`.

Make sure you protect your secrets and identities files with secure permissions:

    chmod 0600 ~/.s3bu/secrets.yml
    chmod 0600 ~/.s3bu/identities.txt

The applications won't run if there are group or world access permissions on these files.

### Update The Job Configurations

The job file templates are written to `local/jobs`. They are all identical and need to be edited 
for the task and uploaded to the repository.

Once it's ready to upload, you can use a command like this:

    s3jobupload -p s3backup mybucketname myjobname local/jobs/myjobname-000.yml

This will encrypt the job file so it is opaque in the bucket, and increments the version 
number so the uploaded job file will be named `myjobname-001.yml`.

### Running Your Backup

Now you're ready to run the backup job:

    s3backup -p s3backup mybucketname myjobname

The backup tool downloads the most recent job configuration (the one with the highest numbered suffix)
and runs the job.

