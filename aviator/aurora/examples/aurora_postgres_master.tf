module "aurora_postgresql_master" {
  # This needs to be updated once a permanent home is found
  source = "C:\\cftemplates\\1011039-aws-Rackspace-FAWS-Support-Engineering\\modules\\aurora"

  ##################
  # VPC Configuration
  ##################

  subnets         = "${local.subnets}"         #  Required
  security_groups = "${local.security_groups}" #  Required

  # existing_subnet_group = "some-subnet-group-name"


  ##################
  # Backups and Maintenance
  ##################


  # maintenance_window      = "Sun:07:00-Sun:08:00"
  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_arn         = "some-cluster-snapshot-arn"


  ##################
  # Basic RDS
  ##################

  name           = "sample-aurora-postgresql-master" #  Required
  engine         = "aurora-postgresql"               #  Required
  instance_class = "db.r4.large"                     #  Required

  # dbname         = "mydb"
  # engine_version = "9.6.8"
  # port           = "5432"


  ##################
  # RDS Advanced
  ##################

  storage_encrypted = true #  Parameter defaults to false, but enabled for Cross Region Replication example

  # publicly_accessible                   = false
  # binlog_format                         = "OFF"
  # auto_minor_version_upgrade            = true
  # family                                = "aurora-postgresql9.6"
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
}
