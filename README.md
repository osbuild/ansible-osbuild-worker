# osbuild.osbuild_worker

This roles installs, configures and starts `osbuild-composer` remote worker on the host.

## Role Variables

The role has a few required variables, which must be provided by the user in order for the role to not fail.

**Required variables are:**

* `osbuild_worker_server_hostname`
* `osbuild_worker_authentication_oauth_url`
* `osbuild_worker_authentication_client_id`
* Any of
  * `osbuild_worker_authentication_client_secret_file`
  * `osbuild_worker_authentication_offline_token_file`

The rest of the variables are not required and if set, they enable optional functionality in the worker.

Variables that the user can set are listed and explained below:

```yaml
#################################
# General configuration options #
#################################

# The hostname of the osbuild-composer API server.
# REQUIRED
osbuild_worker_server_hostname: ""
# The osbuild-composer server API base path. If empty, the default value is used.
osbuild_worker_server_api_base_path: ""
# Force the restart of the worker service even if the configuration has not changed.
osbuild_worker_force_restart: false

# Worker proxy configuration.
osbuild_worker_proxy_server_hostname: ""
osbuild_worker_proxy_server_port: 443
osbuild_worker_no_proxy_domains: []

# Logging configuration
# additional information to be logged where the instance is deployed
# you should override with "staging", "production" or similar
# defaults to {{ osbuild_worker_deployment_channel_default }}
osbuild_worker_deployment_channel: ""

################################################
# Worker authentication to the composer server #
################################################

# The OAuth server URL.
# REQUIRED
osbuild_worker_authentication_oauth_url: ""
# The OAuth client ID.
# REQUIRED
osbuild_worker_authentication_client_id: ""
# Local path to the worker OAuth client secret file. If not empty, this file will be
# copied to the worker to {{ osbuild_worker_authentication_client_secret_path }}.
# REQUIRED (if osbuild_worker_authentication_offline_token_file not specified)
osbuild_worker_authentication_client_secret_file: ""
# Path to the worker OAuth client secret file on the worker. If empty,
# defaults to {{ osbuild_worker_authentication_client_secret_path_default }}.
osbuild_worker_authentication_client_secret_path: ""
# Local path to the worker OAuth offline token file. If not empty, this file will be
# copied to the worker to {{ osbuild_worker_authentication_offline_token_path }}.
# REQUIRED (if osbuild_worker_authentication_client_secret_file not specified)
osbuild_worker_authentication_offline_token_file: ""
# Path to the worker OAuth offline token file on the worker. If empty,
# defaults to {{ osbuild_worker_authentication_offline_token_path_default }}.
osbuild_worker_authentication_offline_token_path: ""

##########################
# Configuration for Koji #
##########################

osbuild_worker_koji_instances: []
# example:
# osbuild_worker_koji_instances:
#   - koji_host: "koji.example.com"
#     krb_principal: "osbuild-automation@EXAMPLE.COM"
#     # Local path to the krb keytab file. If not empty, this file will be
#     # copied to the worker to {{ krb_keytab_path }}.
#     krb_keytab_file: ""
#     # Path to the krb keytab file on the worker. If empty, a default path
#     # under {{ osbuild_worker_config_dir }} with filename
#     # "client_{{ koji_host }}.keytab" will be used.
#     krb_keytab_path: ""
#     relax_timeout_factor: 5

###########################
# Configuration for Azure #
###########################

# Local path to the Azure credentials file. If not empty, this file will be
# copied to the worker to {{ osbuild_worker_azure_credentials_path }}.
osbuild_worker_azure_credentials_file: ""
# Path to the Azure credentials file on the worker. If empty,
# defaults to {{ osbuild_worker_azure_credentials_path_default }}.
osbuild_worker_azure_credentials_path: ""
# Number of threads to use when uploading image blob to Azure. If 0, no
# explicit value is set in the configuration file and the worker will use
# its internal default. Set to a positive integer to override the default.
osbuild_worker_azure_upload_threads: 0

#########################
# Configuration for AWS #
#########################

# Local path to the AWS credentials file. If not empty, this file will be
# copied to the worker to {{ osbuild_worker_aws_credentials_path }}.
osbuild_worker_aws_credentials_file: ""
# Path to the AWS credentials file on the worker. If empty,
# defaults to {{ osbuild_worker_aws_credentials_path_default }}.
osbuild_worker_aws_credentials_path: ""
osbuild_worker_aws_bucket: ""

#########################
# Configuration for GCP #
#########################

# Local path to the GCP credentials file. If not empty, this file will be
# copied to the worker to {{ osbuild_worker_gcp_credentials_path }}.
osbuild_worker_gcp_credentials_file: ""
# Path to the GCP credentials file on the worker. If empty,
# defaults to {{ osbuild_worker_gcp_credentials_path_default }}.
osbuild_worker_gcp_credentials_path: ""
osbuild_worker_gcp_bucket: ""
```

### Internal variables

The role also uses some internal variables, which usually hold default values used by the role. Although the user can override them when using the role, this is discouraged. Do it only if you know what you are doing. Backward compatibility is not guaranteed when setting those.

```yaml
osbuild_worker_config_dir: /etc/osbuild-worker
osbuild_worker_config_dir_mode: '0755'

osbuild_worker_config_file: "{{ osbuild_worker_config_dir }}/osbuild-worker.toml"
osbuild_worker_config_file_mode: '0644'

osbuild_worker_remote_worker_service_name: osbuild-remote-worker@
osbuild_worker_remote_worker_service_dropin_dir: /etc/systemd/system/{{ osbuild_worker_remote_worker_service_name }}.service.d
osbuild_worker_remote_worker_service_proxy_dropin_file: "{{ osbuild_worker_remote_worker_service_dropin_dir }}/proxy.conf"

osbuild_worker_secrets_owner: root
osbuild_worker_secrets_group: root
osbuild_worker_secrets_mode: '0400'

osbuild_worker_authentication_client_secret_path_default: "{{ osbuild_worker_config_dir }}/client_secret"
osbuild_worker_authentication_offline_token_path_default: "{{ osbuild_worker_config_dir }}/offline_token"

osbuild_worker_azure_credentials_path_default: "{{ osbuild_worker_config_dir }}/azure-credentials"
osbuild_worker_aws_credentials_path_default: "{{ osbuild_worker_config_dir }}/aws-credentials"
osbuild_worker_gcp_credentials_path_default: "{{ osbuild_worker_config_dir }}/gcp-credentials"
```

## Dependencies

The role has no external dependencies.

## Example Playbook

Below is an example minimal playbook using the role with only the requires role variables specified. This playbook will install and configure remote `osbuild-worker` on the host with authentication settings for connecting to the remote `osbuild-composer` job queue server located at `composer.example.com`. The `client_secret` is expected to be a filename of a local file that will be copied to the remote host by the role.

Note that this example is not very useful, because the worker is not configured with any upload target authentication (e.g. AWS, Azure, GCP or Koji), thus it won't be able o upload the built image anywhere.

```yaml
- hosts: osbuild-worker
  tasks:
    - name: Include osbuild_worker role
      ansible.builtin.include_role:
        name: "osbuild.osbuild_worker"
      vars:
        osbuild_worker_server_hostname: "composer.example.com"
        osbuild_worker_authentication_oauth_url: "oauth-server.example.com"
        osbuild_worker_authentication_client_id: "osbuild-automation"
        osbuild_worker_authentication_client_secret_file: "client_secret"
```

More useful example could be an instance of a remote worker configured with the option to upload built images to a Koji instance as well as to AWS. The following things are assumed:

* `client_secret` is a local filename with OAuth client secret
* `aws_credentials` is a local filename with AWS credentials
* `koji.keytab` is a local filename of Kerberos keytab file

```yaml
- hosts: osbuild-worker
  tasks:
    - name: Include osbuild_worker role
      ansible.builtin.include_role:
        name: "osbuild.osbuild_worker"
      vars:
        osbuild_worker_server_hostname: "composer.example.com"
        osbuild_worker_authentication_oauth_url: "oauth-server.example.com"
        osbuild_worker_authentication_client_id: "osbuild-automation"
        osbuild_worker_authentication_client_secret_file: "client_secret"
        osbuild_worker_aws_credentials_file: "aws_credentials"
        osbuild_worker_aws_bucket: "my-s3-bucket"
        osbuild_worker_koji_instances:
          - koji_host: "koji.example.com"
            krb_principal: "osbuild-automation@EXAMPLE.COM"
            krb_keytab_file: "koji.keytab"
```

## What is NOT supported

* Configuring a local osbuild-worker.
* Configuring the "generic S3" upload target authentication.
* Configuring the "container registry" upload target authentication.
* Configuring the path to `dnf-json` binary.
* Configuring the proxy server in the worker configuration.
* Configuring the TLS client certificate authentication.
* Configuring the osbuild-composer server TLS CA certificate.

## Tests

There are automated tests in the `.github` folder. To run them locally
before creating a PR you can run

`make tests`

it is expected that `make` and `docker` is installed.
Those test replicate a subset of the github tests as close as possible to see problems.

## License

Apache-2.0
