# S3 Backup Infrastructure

This is a partner repository for the [s3backup](https://github.com/studio1767/s3backup) project. It creates the 
infrastrucuture needed for that project including:

* AWS S3 bucket
* AWS IAM users with the necessary permissions and access keys
* Age encryption identities and recipients
* Passphrase secret files for each user
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

This walks though getting the system built and each user ready to go without going into detail on the 
internals and without explaining how to use the tools.

See the main [s3backup](https://github.com/studio1767/s3backup) repository for those details.

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

