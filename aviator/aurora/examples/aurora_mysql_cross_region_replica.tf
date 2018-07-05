data "aws_kms_alias" "rds_crr" {
  provider = "aws.oregon"
  name     = "alias/aws/rds"
}

module "aurora_mysql_replica" {
  # This needs to be updated once a permanent home is found
  source = "C:\\cftemplates\\1011039-aws-Rackspace-FAWS-Support-Engineering\\modules\\aurora"

  providers = {
    aws = "aws.oregon"
  }

  ##################
  # VPC Configuration
  ##################

  subnets         = "${local.subnets_dr}"         #  Required
  security_groups = "${local.security_groups_dr}" #  Required

  # existing_subnet_group = "some-subnet-group-name"


  ##################
  # Backups and Maintenance
  ##################


  # maintenance_window      = "Sun:07:00-Sun:08:00"
  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_arn          = "some-cluster-snapshot-arn"


  ##################
  # Basic RDS
  ##################

  name           = "sample-aurora-mysql-replica" #  Required
  engine         = "aurora-mysql"                #  Required
  instance_class = "db.t2.medium"                #  Required

  # dbname         = "mydb"
  # engine_version = "5.7.12"
  # port           = "3306"


  ##################
  # RDS Advanced
  ##################

  storage_encrypted = true                                           #  Parameter defaults to false, but enabled for Cross Region Replication example
  kms_key_id        = "${data.aws_kms_alias.rds_crr.target_key_arn}" # Parameter needed since we are replicating an db instance with encrypted storage.
  binlog_format     = "MIXED"                                        # Parameter needed to enable replication

  # publicly_accessible                   = false
  # binlog_format                         = "OFF"
  # auto_minor_version_upgrade            = true
  # family                                = "aurora-mysql5.7"
  # replica_instances                     = 1
  # storage_encrypted                     = false
  # kms_key_id                            = "some-kms-key-id"
  # parameters                            = []
  # existing_parameter_group_name         = "some-parameter-group-name"
  # cluster_parameters                    = []
  # existing_cluster_parameter_group_name = "some-parameter-group-name"
  # options                               = []
  # existing_option_group_name            = "some-option-group-name"


  ##################
  # RDS Monitoring
  ##################


  # notification_topic           = "arn:aws:sns:<region>:<account>:some-topic"
  # alarm_write_iops_limit       = 100000
  # alarm_read_iops_limit        = 100000
  # alarm_cpu_limit              = 60
  # rackspace_alarms_enabled     = false
  # monitoring_interval          = 0
  # existing_monitoring_role_arn = ""


  ##################
  # Authentication information
  ##################

  password = "${local.password}" #  Required

  # username = "dbadmin"


  ##################
  # Other parameters
  ##################


  # environment = "Production"


  # tags = {
  #   SomeTag = "SomeValue"
  # }

  source_cluster = "${module.aurora_mysql_master.cluster_id}"
  source_region  = "${data.aws_region.current.name}"
}
