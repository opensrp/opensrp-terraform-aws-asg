data "aws_vpc" "opensrp-vpc" {
  id = var.vpc_id
}

data "aws_subnet_ids" "opensrp" {
  vpc_id = data.aws_vpc.opensrp-vpc.id
}

data "template_file" "init-blue" {
  template = file("${path.module}/init.sh.tpl")

  vars = {
    group                  = "${var.deployed_app}-${var.project}-${var.env}-blue"
    region                 = var.compute_region
    mybatis_version        = var.mybatis_version
    run_mybatis_migrations = var.run_mybatis_migrations
  }
}

data "template_file" "init-green" {
  template = file("${path.module}/init.sh.tpl")

  vars = {
    group                  = "${var.deployed_app}-${var.project}-${var.env}-green"
    region                 = var.compute_region
    mybatis_version        = var.mybatis_version
    run_mybatis_migrations = var.run_mybatis_migrations
  }
}

data "template_cloudinit_config" "blue" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"

    content = data.template_file.init-blue.rendered
  }
}

data "template_cloudinit_config" "green" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"

    content = data.template_file.init-green.rendered
  }
}

module "opensrp" {
  source = "git::https://github.com/onaio/terraform-aws-asg-base.git?ref=v0.1.0"

  env                                  = var.env
  project                              = var.project
  project_id                           = var.project_id
  deployed_app                         = var.deployed_app
  owner                                = var.owner
  end_date                             = var.end_date
  alb_bucket_name                      = var.alb_bucket_name
  alb_ssl_policy                       = var.alb_ssl_policy
  route53_zone_name                    = var.route53_zone_name
  service_domain                       = var.service_domain
  iam_server_ssl_cert                  = var.iam_server_ssl_cert
  acm_certificate_domain               = var.acm_certificate_domain
  cnames                               = var.cnames
  data_bucket_name                     = var.data_bucket_name
  iam_s3_user                          = var.iam_s3_user
  vpc_id                               = data.aws_vpc.opensrp-vpc.id
  subnet_ids                           = length(var.alb_subnet_ids) > 0 ? var.alb_subnet_ids : data.aws_subnet_ids.opensrp.ids
  data_bucket_region                   = var.data_bucket_region
  create_certificate                   = var.create_certificate
  health_check_path                    = var.health_check_path
  http_health_check_matcher            = var.http_health_check_matcher
  http_health_check_protocol           = var.http_health_check_protocol
  https_health_check_matcher           = var.https_health_check_matcher
  redirect_paths                       = var.redirect_paths
  create_route53_records               = var.create_route53_records
  create_s3_user                       = var.create_s3_user
  create_s3_bucket                     = var.create_s3_bucket
  enable_alb_logs                      = var.enable_alb_logs
  asg_ssh_cidr_blocks                  = var.asg_ssh_cidr_blocks
  asg_http_cidr_blocks                 = var.asg_http_cidr_blocks
  asg_https_cidr_blocks                = var.asg_https_cidr_blocks
  target_group_port                    = var.target_group_port
  target_group_protocol                = var.target_group_protocol
  alb_logs_user_identifiers            = var.alb_logs_user_identifiers
  cloudwatch_alarm_actions             = var.cloudwatch_alarm_actions
  cloudwatch_ok_actions                = var.cloudwatch_ok_actions
  cloudwatch_insufficient_data_actions = var.cloudwatch_insufficient_data_actions
}

module "opensrp-blue" {
  source = "git::https://github.com/onaio/terraform-aws-asg-compute.git?ref=v0.1.0"

  asg_max_size                         = var.blue_asg_max_size
  asg_min_size                         = var.blue_asg_min_size
  deployment                           = "blue"
  deployed                             = var.deploy_blue
  env                                  = var.env
  project                              = var.project
  project_id                           = var.project_id
  deployed_app                         = var.deployed_app
  owner                                = var.owner
  end_date                             = var.end_date
  ssh_key_name                         = var.ssh_key_name
  ami                                  = var.blue_ami
  instance_type                        = var.instance_type
  attached_volume_size                 = var.attached_volume_size
  cloudwatch_alarm_actions             = var.cloudwatch_alarm_actions
  cloudwatch_ok_actions                = var.cloudwatch_ok_actions
  cloudwatch_insufficient_data_actions = var.cloudwatch_insufficient_data_actions
  target_group_arns                    = module.opensrp.target_group_arns
  security_groups                      = module.opensrp.security_groups
  subnet_ids                           = length(var.hosts_subnet_ids) > 0 ? var.hosts_subnet_ids : data.aws_subnet_ids.opensrp.ids
  user_data                            = data.template_cloudinit_config.blue.rendered
  ec2_instance_role                    = var.ec2_instance_role
}

module "opensrp-green" {
  source = "git::https://github.com/onaio/terraform-aws-asg-compute.git?ref=v0.1.0"

  asg_max_size                         = var.green_asg_max_size
  asg_min_size                         = var.green_asg_min_size
  deployment                           = "green"
  deployed                             = var.deploy_green
  env                                  = var.env
  project                              = var.project
  project_id                           = var.project_id
  deployed_app                         = var.deployed_app
  owner                                = var.owner
  end_date                             = var.end_date
  ssh_key_name                         = var.ssh_key_name
  ami                                  = var.green_ami
  instance_type                        = var.instance_type
  attached_volume_size                 = var.attached_volume_size
  cloudwatch_alarm_actions             = var.cloudwatch_alarm_actions
  cloudwatch_ok_actions                = var.cloudwatch_ok_actions
  cloudwatch_insufficient_data_actions = var.cloudwatch_insufficient_data_actions
  target_group_arns                    = module.opensrp.target_group_arns
  security_groups                      = module.opensrp.security_groups
  subnet_ids                           = length(var.hosts_subnet_ids) > 0 ? var.hosts_subnet_ids : data.aws_subnet_ids.opensrp.ids
  user_data                            = data.template_cloudinit_config.green.rendered
  ec2_instance_role                    = var.ec2_instance_role
}
