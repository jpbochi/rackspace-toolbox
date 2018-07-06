resource "random_string" "r_string" {
  length  = 16
  upper   = true
  lower   = false
  number  = true
  special = false
}

locals {
  user_data_map = {
    rhel6    = "${file("${path.module}/text/rhel_centos_6_userdata.sh")}"
    rhel7    = "${file("${path.module}/text/rhel_centos_7_userdata.sh")}"
    centos6  = "${file("${path.module}/text/rhel_centos_6_userdata.sh")}"
    centos7  = "${file("${path.module}/text/rhel_centos_7_userdata.sh")}"
    ubuntu14 = "${file("${path.module}/text/ubuntu_userdata.sh")}"
    ubuntu16 = "${file("${path.module}/text/ubuntu_userdata.sh")}"
  }

  ebs_device_map = {
    rhel6    = "/dev/sdf"
    rhel7    = "/dev/sdf"
    centos6  = "/dev/sdf"
    centos7  = "/dev/sdf"
    windows  = "xvdf"
    ubuntu14 = "/dev/sdf"
    ubuntu16 = "/dev/sdf"
    amazon   = "/dev/sdf"
  }

  tags = {
    ServiceProvider = "Rackspace"
    Environment     = "${var.environment}"
    Backup          = "${var.backup_tag_value}"
    SSMInventory    = "${var.perform_ssm_inventory_tag}"
    "Patch Group"   = "${var.ssm_patching_group}"
  }

  # This is a list of ssm main steps
  default_ssm_cmd_list = [
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "AWS-ConfigureAWSPackage",
          "documentParameters": {
            "action": "Install",
            "name": "AmazonCloudWatchAgent"
          },
          "documentType": "SSMDocument"
        },
        "name": "InstallCWAgent",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "AmazonCloudWatch-ManageAgent",
          "documentParameters": {
            "action": "configure",
            "optionalConfigurationSource": "ssm",
            "optionalConfigurationLocation": "${aws_ssm_parameter.cwagentparam.name}",
            "optionalRestart": "yes",
            "name": "AmazonCloudWatchAgent"
          },
          "documentType": "SSMDocument"
        },
        "name": "ConfigureCWAgent",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "arn:aws:ssm:${data.aws_region.current_region.name}:507897595701:document/Rack-ConfigureAWSTimeSync",
          "documentType": "SSMDocument"
        },
        "name": "SetupTimeSync",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "arn:aws:ssm:${data.aws_region.current_region.name}:507897595701:document/Rack-Install_ScaleFT",
          "documentType": "SSMDocument"
        },
        "name": "SetupPassport",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "arn:aws:ssm:${data.aws_region.current_region.name}:507897595701:document/Rack-Install_Package",
          "documentParameters": {
            "Packages": "sysstat ltrace strace iptraf tcpdump"
          },
          "documentType": "SSMDocument"
        },
        "name": "DiagnosticTools",
        "timeoutSeconds": 300
      }
EOF
    },
    {
      ssm_add_step = <<EOF
      {
        "action": "aws:runDocument",
        "inputs": {
          "documentPath": "AWS-UpdateSSMAgent",
          "documentType": "SSMDocument"
        },
        "name": "UpdateSSMAgent",
        "timeoutSeconds": 300
      }
EOF
    },
  ]

  ssm_codedeploy_include = {
    enabled = <<EOF
    {
      "action": "aws:runDocument",
      "inputs": {
        "documentPath": "arn:aws:ssm:${data.aws_region.current_region.name}:507897595701:document/Rack-Install_CodeDeploy",
        "documentType": "SSMDocument"
      },
      "name": "InstallCodeDeployAgent"
    }
EOF

    disabled = ""
  }

  codedeploy_install = "${var.install_codedeploy_agent ? "enabled" : "disabled"}"

  ssm_command_count = 6
}

data "aws_region" "current_region" {}
data "aws_caller_identity" "current_account" {}

#
# IAM Policies
#

data "aws_iam_policy_document" "mod_ec2_assume_role_policy_doc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "mod_ec2_instance_role_policies" {
  statement {
    effect    = "Allow"
    actions   = ["cloudformation:Describe"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:CreateAssociation",
      "ssm:DescribeInstanceInformation",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "logs:CreateLogStream",
      "ec2:DescribeTags",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "ssm:GetParameter",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeTags"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "create_instance_role_policy" {
  name        = "InstanceRolePolicy-${var.resource_name}"
  description = "Rackspace Instance Role Policies for EC2"
  policy      = "${data.aws_iam_policy_document.mod_ec2_instance_role_policies.json}"
}

resource "aws_iam_role" "mod_ec2_instance_role" {
  name               = "InstanceRole-${var.resource_name}"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.mod_ec2_assume_role_policy_doc.json}"
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = "${aws_iam_role.mod_ec2_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "attach_codedeploy_policy" {
  count      = "${var.install_codedeploy_agent ? 1 : 0}"
  role       = "${aws_iam_role.mod_ec2_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_role_policy_attachment" "attach_instance_role_policy" {
  role       = "${aws_iam_role.mod_ec2_instance_role.name}"
  policy_arn = "${aws_iam_policy.create_instance_role_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "attach_additonal_policies" {
  count      = "${var.instance_role_managed_policy_arn_count}"
  role       = "${aws_iam_role.mod_ec2_instance_role.name}"
  policy_arn = "${element(var.instance_role_managed_policy_arns, count.index)}"
}

resource "aws_iam_instance_profile" "instance_role_instance_profile" {
  name = "InstanceRoleInstanceProfile-${var.resource_name}"
  role = "${aws_iam_role.mod_ec2_instance_role.name}"
  path = "/"
}

#
# SSM Association
#

data "template_file" "ssm_command_docs" {
  template = "$${ssm_cmd_json}"

  count = "${local.ssm_command_count}"

  vars {
    ssm_cmd_json = "${lookup(local.default_ssm_cmd_list[count.index], "ssm_add_step")}"
  }
}

data "template_file" "additional_ssm_docs" {
  template = "$${addtional_ssm_cmd_json}"
  count    = "${var.addtional_ssm_bootstrap_step_count}"

  vars {
    addtional_ssm_cmd_json = "${lookup(var.addtional_ssm_bootstrap_list[count.index], "ssm_add_step")}"
  }
}

data "template_file" "ssm_bootstrap_template" {
  template = "${file("${path.module}/text/ssm_bootstrap_template.json")}"

  vars {
    run_command_list = "${join(",",compact(concat(data.template_file.ssm_command_docs.*.rendered, list(local.ssm_codedeploy_include[local.codedeploy_install]), data.template_file.additional_ssm_docs.*.rendered)))}"
  }
}

resource "aws_ssm_document" "ssm_bootstrap_doc" {
  name            = "SSMDocument-${var.resource_name}"
  document_type   = "Command"
  document_format = "JSON"
  content         = "${data.template_file.ssm_bootstrap_template.rendered}"
}

resource "aws_ssm_parameter" "cwagentparam" {
  name        = "CWAgent-${var.resource_name}"
  description = "${var.resource_name} Cloudwatch Agent configuration"
  type        = "String"
  value       = "${replace(replace(file("${path.module}/text/cw_agent_param.txt"),"((SYSTEM_LOG_GROUP_NAME))",aws_cloudwatch_log_group.system_logs.name),"((APPLICATION_LOG_GROUP_NAME))",aws_cloudwatch_log_group.application_logs.name)}"
}

resource "aws_ssm_association" "ssm_bootstrap_assoc" {
  name                = "${aws_ssm_document.ssm_bootstrap_doc.name}"
  schedule_expression = "${var.ssm_association_refresh_rate}"

  targets {
    key = "InstanceIds"

    values = ["${coalescelist(aws_instance.mod_ec2_instance_no_secondary_ebs.*.id, aws_instance.mod_ec2_instance_with_secondary_ebs.*.id)}"]
  }
}

#
# CloudWatch and Logging
#

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "${var.resource_name}-SystemLogs"
  retention_in_days = "${var.cloudwatch_log_retention}"
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "${var.resource_name}-ApplicationLogs"
  retention_in_days = "${var.cloudwatch_log_retention}"
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_system_alarm_ticket" {
  count               = "${var.instance_count}"
  alarm_name          = "${join("-", list("StatusCheckFailedSystemAlarmTicket", var.resource_name, format("%03d",count.index+1)))}"
  alarm_description   = "Status checks have failed for system, generating ticket."
  namespace           = "AWS/EC2"
  statistic           = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  unit                = "Count"
  evaluation_periods  = "2"
  period              = "60"
  metric_name         = "StatusCheckFailed_System"
  alarm_actions       = ["arn:aws:sns:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_account.account_id}:rackspace-support-emergency"]
  ok_actions          = ["arn:aws:sns:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_account.account_id}:rackspace-support-emergency"]

  dimensions {
    # coalescelist and list("novalue") were used here due to element not being able to handle empty lists, even if conditional will not allow portion to execute
    InstanceId = "${var.primary_ebs_volume_size != "" ? element(coalescelist(aws_instance.mod_ec2_instance_with_secondary_ebs.*.id, list("novalue")), count.index) : element(coalescelist(aws_instance.mod_ec2_instance_no_secondary_ebs.*.id, list("novalue")), count.index)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_instance_alarm_reboot" {
  count               = "${var.instance_count}"
  alarm_name          = "${join("-", list("StatusCheckFailedInstanceAlarmReboot", var.resource_name, format("%03d",count.index+1)))}"
  alarm_description   = "Status checks have failed, rebooting system."
  namespace           = "AWS/EC2"
  statistic           = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  unit                = "Count"
  evaluation_periods  = "5"
  period              = "60"
  metric_name         = "StatusCheckFailed_Instance"
  alarm_actions       = ["arn:aws:swf:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_account.account_id}:action/actions/AWS_EC2.InstanceId.Reboot/1.0"]

  dimensions {
    # coalescelist and list("novalue") were used here due to element not being able to handle empty lists, even if conditional will not allow portion to execute
    InstanceId = "${var.primary_ebs_volume_size != "" ? element(coalescelist(aws_instance.mod_ec2_instance_with_secondary_ebs.*.id, list("novalue")), count.index) : element(coalescelist(aws_instance.mod_ec2_instance_no_secondary_ebs.*.id, list("novalue")), count.index)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_system_alarm_recover" {
  count               = "${var.instance_count}"
  alarm_name          = "${join("-", list("StatusCheckFailedSystemAlarmRecover", var.resource_name, format("%03d",count.index+1)))}"
  alarm_description   = "Status checks have failed for system, recovering instance"
  namespace           = "AWS/EC2"
  statistic           = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  unit                = "Count"
  evaluation_periods  = "2"
  period              = "60"
  metric_name         = "StatusCheckFailed_System"
  alarm_actions       = ["arn:aws:automate:${data.aws_region.current_region.name}:ec2:recover"]

  dimensions {
    # coalescelist and list("novalue") were used here due to element not being able to handle empty lists, even if conditional will not allow portion to execute
    InstanceId = "${var.primary_ebs_volume_size != "" ? element(coalescelist(aws_instance.mod_ec2_instance_with_secondary_ebs.*.id, list("novalue")), count.index) : element(coalescelist(aws_instance.mod_ec2_instance_no_secondary_ebs.*.id, list("novalue")), count.index)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_instance_alarm_ticket" {
  count               = "${var.instance_count}"
  alarm_name          = "${join("-", list("StatusCheckFailedInstanceAlarmTicket", var.resource_name, format("%03d",count.index+1)))}"
  alarm_description   = "Status checks have failed, generating ticket."
  namespace           = "AWS/EC2"
  statistic           = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  unit                = "Count"
  evaluation_periods  = "10"
  period              = "60"
  metric_name         = "StatusCheckFailed_Instance"
  ok_actions          = ["arn:aws:sns:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_account.account_id}:rackspace-support-emergency"]
  alarm_actions       = ["arn:aws:sns:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_account.account_id}:rackspace-support-emergency"]

  dimensions {
    # coalescelist and list("novalue") were used here due to element not being able to handle empty lists, even if conditional will not allow portion to execute
    InstanceId = "${var.primary_ebs_volume_size != "" ? element(coalescelist(aws_instance.mod_ec2_instance_with_secondary_ebs.*.id, list("novalue")), count.index) : element(coalescelist(aws_instance.mod_ec2_instance_no_secondary_ebs.*.id, list("novalue")), count.index)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  count               = "${var.instance_count}"
  alarm_name          = "${join("-", list("CPUAlarmHigh", var.resource_name, format("%03d",count.index+1)))}"
  alarm_description   = "CPU Alarm ${var.cw_cpu_high_operator} ${var.cw_cpu_high_threshold}% for ${var.cw_cpu_high_period} seconds ${var.cw_cpu_high_evaluations} times."
  namespace           = "AWS/EC2"
  statistic           = "Average"
  comparison_operator = "${var.cw_cpu_high_operator}"
  threshold           = "${var.cw_cpu_high_threshold}"
  evaluation_periods  = "${var.cw_cpu_high_evaluations}"
  period              = "${var.cw_cpu_high_period}"
  metric_name         = "CPUUtilization"
  ok_actions          = []
  alarm_actions       = ["${compact(list(var.alarm_notification_topic))}"]

  dimensions {
    # coalescelist and list("novalue") were used here due to element not being able to handle empty lists, even if conditional will not allow portion to execute
    InstanceId = "${var.primary_ebs_volume_size != "" ? element(coalescelist(aws_instance.mod_ec2_instance_with_secondary_ebs.*.id, list("novalue")), count.index) : element(coalescelist(aws_instance.mod_ec2_instance_no_secondary_ebs.*.id, list("novalue")), count.index)}"
  }
}

#
# Provisioning of Instance(s)
#

resource "aws_instance" "mod_ec2_instance_no_secondary_ebs" {
  ami                    = "${var.image_id}"
  count                  = "${var.secondary_ebs_volume_size != "" ? 0 : var.instance_count}"
  subnet_id              = "${var.ec2_subnet}"
  vpc_security_group_ids = ["${var.security_group_list}"]
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_pair}"
  ebs_optimized          = "${var.enable_ebs_optimization}"
  tenancy                = "${var.tenancy}"
  monitoring             = "${var.detailed_monitoring}"
  iam_instance_profile   = "${aws_iam_instance_profile.instance_role_instance_profile.name}"
  user_data_base64       = "${base64encode(lookup(local.user_data_map, var.ec2_os, ""))}"

  # coalescelist and list("") were used here due to element not being able to handle empty lists, even if conditional will not allow portion to execute
  private_ip              = "${element(coalescelist(var.private_ip_address, list("")), count.index)}"
  disable_api_termination = "${var.disable_api_termination}"

  credit_specification {
    cpu_credits = "${var.t2_unlimited_mode}"
  }

  root_block_device {
    volume_type = "${var.primary_ebs_volume_type}"
    volume_size = "${var.primary_ebs_volume_size}"
    iops        = "${var.primary_ebs_volume_iops}"
  }

  timeouts {
    create = "${var.creation_policy_timeout}"
  }

  tags = "${merge(
    map("Name", "${var.resource_name}${var.instance_count > 1 ? format("-%03d",count.index+1) : ""}"),
    local.tags,
    var.additional_tags
  )}"
}

resource "aws_instance" "mod_ec2_instance_with_secondary_ebs" {
  ami                    = "${var.image_id}"
  count                  = "${var.secondary_ebs_volume_size != "" ? var.instance_count : 0}"
  subnet_id              = "${var.ec2_subnet}"
  vpc_security_group_ids = ["${var.security_group_list}"]
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_pair}"
  ebs_optimized          = "${var.enable_ebs_optimization}"
  tenancy                = "${var.tenancy}"
  monitoring             = "${var.detailed_monitoring}"
  iam_instance_profile   = "${aws_iam_instance_profile.instance_role_instance_profile.name}"
  user_data_base64       = "${base64encode(lookup(local.user_data_map, var.ec2_os, ""))}"

  # coalescelist and list("") were used here due to element not being able to handle empty lists, even if conditional will not allow portion to execute
  private_ip              = "${element(coalescelist(var.private_ip_address, list("")), count.index)}"
  disable_api_termination = "${var.disable_api_termination}"

  credit_specification {
    cpu_credits = "${var.t2_unlimited_mode}"
  }

  root_block_device {
    volume_type = "${var.primary_ebs_volume_type}"
    volume_size = "${var.primary_ebs_volume_size}"
    iops        = "${var.primary_ebs_volume_iops}"
  }

  ebs_block_device {
    device_name = "${lookup(local.ebs_device_map, var.ec2_os)}"
    volume_type = "${var.secondary_ebs_volume_type}"
    volume_size = "${var.secondary_ebs_volume_size}"
    iops        = "${var.secondary_ebs_volume_iops}"
    encrypted   = "${var.encrypt_secondary_ebs_volume}"
  }

  timeouts {
    create = "${var.creation_policy_timeout}"
  }

  tags = "${merge(
    map("Name", "${var.resource_name}${var.instance_count > 1 ? format("-%03d",count.index+1) : ""}"),
    local.tags,
    var.additional_tags
  )}"
}

resource "aws_eip_association" "eip_assoc" {
  count = "${var.eip_allocation_id_count}"

  # coalescelist and list("novalue") were used here due to element not being able to handle empty lists, even if conditional will not allow portion to execute
  instance_id   = "${var.primary_ebs_volume_size != "" ? element(coalescelist(aws_instance.mod_ec2_instance_with_secondary_ebs.*.id, list("novalue")), count.index) : element(coalescelist(aws_instance.mod_ec2_instance_no_secondary_ebs.*.id, list("novalue")), count.index)}"
  allocation_id = "${element(var.eip_allocation_id_list, count.index)}"
}
