
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alarm_cpu_limit | CloudWatch CPUUtilization Threshold | string | `60` | no |
| alarm_free_space_limit | CloudWatch Free Storage Space Limit Threshold (Bytes) | string | `1024000000` | no |
| alarm_read_iops_limit | CloudWatch Read IOPSLimit Threshold | string | `100` | no |
| alarm_write_iops_limit | CloudWatch Write IOPSLimit Threshold | string | `100` | no |
| apply_immediately | Should database modifications be applied immediately? | string | `false` | no |
| auto_minor_version_upgrade | Boolean value that indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | string | `true` | no |
| backup_retention_period | The number of days for which automated backups are retained. Setting this parameter to a positive number enables backups. Setting this parameter to 0 disables automated backups. Compass best practice is 30 or more days. | string | `35` | no |
| backup_window | The daily time range during which automated backups are created if automated backups are enabled. | string | `05:00-06:00` | no |
| character_set_name | (Optional) The character set name to use for DB encoding in Oracle instances. This can't be changed. See Oracle Character Sets Supported in Amazon RDS for more information. | string | `` | no |
| copy_tags_to_snapshot | Indicates whether to copy all of the user-defined tags from the DB instance to snapshots of the DB instance. | string | `true` | no |
| db_snapshot_id | The name of a DB snapshot (optional). | string | `` | no |
| dbname | The DB name to create. If omitted, no database is created initially | string | `` | no |
| engine | Database Engine Type.  Allowed values: mariadb, mysql, oracle-ee, oracle-se, oracle-se1, oracle-se2, postgres, sqlserver-ee, sqlserver-ex, sqlserver-se, sqlserver-web | string | - | yes |
| engine_version | Database Engine Minor Version http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html | string | `` | no |
| environment | Application environment for which this network is being created. one of: ('Development', 'Integration', 'PreProduction', 'Production', 'QA', 'Staging', 'Test') | string | `Development` | no |
| existing_monitoring_role | ARN of an existing enhanced monitoring role to use for this instance. (OPTIONAL) | string | `` | no |
| existing_option_group_name | The existing option group to use for this instance. (OPTIONAL) | string | `` | no |
| existing_parameter_group_name | The existing parameter group to use for this instance. (OPTIONAL) | string | `` | no |
| existing_subnet_group | The existing DB subnet group to use for this instance (OPTIONAL) | string | `` | no |
| family | Parameter Group Family Name (ex. mysql5.7,sqlserver-se-12.0,postgres9.5,oracle-se-12.1,mariadb10.1) | string | `` | no |
| iam_authentication_enabled | Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled | string | `false` | no |
| instance_class | The database instance type. | string | - | yes |
| kms_key_id | KMS Key Arn to use for storage encryption. (OPTIONAL) | string | `` | no |
| license_model | License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1 | string | `` | no |
| maintenance_window | The daily time range during which automated backups are created if automated backups are enabled. | string | `Sun:07:00-Sun:08:00` | no |
| monitoring_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60. | string | `0` | no |
| multi_az | Create a multi-AZ RDS database instance | string | `false` | no |
| name | The name prefix to use for the resources created in this module. | string | - | yes |
| notification_topic | SNS Topic ARN to use for customer notifications from CloudWatch alarms. (OPTIONAL) | string | `` | no |
| options | List of custom options to apply to the option group. | list | `<list>` | no |
| parameters | List of custom parameters to apply to the parameter group. | list | `<list>` | no |
| password | Password for the local administrator account. | string | - | yes |
| port | The port on which the DB accepts connections | string | `` | no |
| publicly_accessible | Boolean value that indicates whether the database instance is an Internet-facing instance. | string | `false` | no |
| rackspace_alarms_enabled | Specifies whether non-emergency rackspace alarms will create a ticket. | string | `false` | no |
| security_groups | A list of EC2 security groups to assign to this resource | list | - | yes |
| source_db | The ID of the source DB instance.  For cross region replicas, the full ARN should be provided | string | `` | no |
| storage_encrypted | Specifies whether the DB instance is encrypted | string | `false` | no |
| storage_iops | The amount of provisioned IOPS. Setting this implies a storage_type of 'io1' | string | `0` | no |
| storage_size | Select RDS Volume Size in GB. | string | `` | no |
| storage_type | Select RDS Volume Type. | string | `gp2` | no |
| subnets | Subnets for RDS Instances | list | - | yes |
| tags | Custom tags to apply to all resources. | map | `<map>` | no |
| timezone | The server time zone | string | `` | no |
| username | The name of master user for the client DB instance. | string | `dbadmin` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_endpoint | Database endpoint |
| db_endpoint_address | Address of database endpoint |
| db_endpoint_port | Port of database endpoint |
| db_instance | The DB instance identifier |
| db_instance_arn | The DB instance ARN |
| jdbc_connection_string | JDBC connection string for database |
| monitoring_role | The IAM role used for Enhanced Monitoring |
| option_group | The Option Group used by the DB Instance |
| parameter_group | The Parameter Group used by the DB Instance |
| subnet_group | The DB Subnet Group used by the DB Instance |

