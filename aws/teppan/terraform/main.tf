# variable

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
    default = "ap-northeast-1"
}
variable "key_pair_name" {}
variable "certificate_arn" {}

variable "environment_name" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}

variable "app_instance_type" {}
variable "app_instance_volume" {}
variable "app_instance_ec2_ami" {}

variable "maintenance_instance_ec2_ami" {}

variable "route53_zone_id" {}
variable "route53_record_name" {}

# main structures

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.region}"
}

## VPC & Subnet

resource "aws_vpc" "VpcCurrent" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "false"
    tags {
      Name = "vpc-${var.environment_name}"
    }
}

resource "aws_subnet" "SbnApAza" {
  vpc_id     = "${aws_vpc.VpcCurrent.id}"
  availability_zone = "ap-northeast-1a"
  cidr_block = "10.0.11.0/24"
  tags { Name = "sbn-ap-aza" }
}

resource "aws_subnet" "SbnApAzc" {
  vpc_id     = "${aws_vpc.VpcCurrent.id}"
  availability_zone = "ap-northeast-1c"
  cidr_block = "10.0.12.0/24"
  tags { Name = "sbn-ap-azc" }
}

resource "aws_subnet" "SbnDbAza" {
  vpc_id     = "${aws_vpc.VpcCurrent.id}"
  availability_zone = "ap-northeast-1a"
  cidr_block = "10.0.21.0/24"
  tags { Name = "sbn-db-aza" }
}

resource "aws_subnet" "SbnDbAzc" {
  vpc_id     = "${aws_vpc.VpcCurrent.id}"
  availability_zone = "ap-northeast-1c"
  cidr_block = "10.0.22.0/24"
  tags { Name = "sbn-db-azc" }
}

resource "aws_subnet" "SbnMaintenanceAza" {
  vpc_id     = "${aws_vpc.VpcCurrent.id}"
  availability_zone = "ap-northeast-1a"
  cidr_block = "10.0.91.0/24"
  tags { Name = "sbn-maintenance-aza" }
}

## Internet Gateway & Route Table

resource "aws_internet_gateway" "IgwRouter01" {
    vpc_id = "${aws_vpc.VpcCurrent.id}"
    tags { Name = "igw-router01" }
}
resource "aws_route_table" "RtbPublic01" {
  vpc_id     = "${aws_vpc.VpcCurrent.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IgwRouter01.id}"
  }
  tags { Name = "rtb-public01" }
}
resource "aws_route_table_association" "RtbPublic01Rta01" {
  subnet_id      = "${aws_subnet.SbnMaintenanceAza.id}"
  route_table_id = "${aws_route_table.RtbPublic01.id}"
}
resource "aws_route_table_association" "RtbPublic01Rta02" {
  subnet_id      = "${aws_subnet.SbnApAza.id}"
  route_table_id = "${aws_route_table.RtbPublic01.id}"
}
resource "aws_route_table_association" "RtbPublic01Rta03" {
  subnet_id      = "${aws_subnet.SbnApAzc.id}"
  route_table_id = "${aws_route_table.RtbPublic01.id}"
}

## Security Group

resource "aws_security_group" "ScgAp" {
  name        = "scg-ap"
  description = "Application role security group"
  vpc_id      = "${aws_vpc.VpcCurrent.id}"
  ingress {
    from_port   = 8080
    to_port     = 8081
    protocol    = "6"
    security_groups = ["${aws_security_group.ScgAlb.id}"]
    description = "from alb traffic only"
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "6"
    security_groups = ["${aws_security_group.ScgMaintenance.id}"]
    description = "from maintenance instance traffic only"
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags { Name = "scg-ap" }
}

resource "aws_security_group" "ScgDb" {
  name        = "scg-db"
  description = "DB role security group"
  vpc_id      = "${aws_vpc.VpcCurrent.id}"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "6"
    security_groups = ["${aws_security_group.ScgMaintenance.id}", "${aws_security_group.ScgAp.id}"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags { Name = "scg-db" }
}

resource "aws_security_group" "ScgAlb" {
  name        = "scg-alb"
  description = "Security Group for Application Load Barancer"
  vpc_id      = "${aws_vpc.VpcCurrent.id}"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags { Name = "scg-alb" }
}

resource "aws_security_group" "ScgMaintenance" {
  name        = "scg-maintenance"
  description = "Security Group for maintenance"
  vpc_id      = "${aws_vpc.VpcCurrent.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"] # 運用時に「マイIP」で制御する
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags { Name = "scg-maintenance" }
}

resource "aws_db_subnet_group" "DbSbnGpAza" {
  name       = "db-sbn-gp-aza"
  description = "DB Subnet Group AZ A"
  subnet_ids = ["${aws_subnet.SbnDbAza.id}", "${aws_subnet.SbnDbAzc.id}"]
  tags { Name = "db-sbn-gp-aza" }
}

## DB(RDS)

resource "aws_db_instance" "RdsCurrent" {
  allocated_storage    = 10
  storage_type         = "gp2" # standard, gp2, io1
  engine               = "postgres"
  engine_version       = "10.1"
  instance_class       = "db.t2.micro"
  multi_az             = true
  publicly_accessible  = false
  identifier           = "rds-${var.environment_name}"
  name                 = "${var.db_name}"
  username             = "${var.db_username}"
  password             = "${var.db_password}"
  db_subnet_group_name = "db-sbn-gp-aza"
  parameter_group_name = "default.postgres10"
  vpc_security_group_ids =["${aws_security_group.ScgDb.id}"]
  skip_final_snapshot  = false
  # backup settings
  backup_retention_period = "7"
  backup_window = "18:00-18:30" #JST03:00
  apply_immediately = "true"

  final_snapshot_identifier = "rds-final-backup-${var.environment_name}"
  tags { Name = "rds-${var.environment_name}" }
}

## EC2 Instance

resource "aws_instance" "Ec2Maintenance01Aza" {
  ami           = "${var.maintenance_instance_ec2_ami}"
  instance_type = "t2.small"
  availability_zone = "ap-northeast-1a"
  subnet_id     = "${aws_subnet.SbnMaintenanceAza.id}"
  vpc_security_group_ids = ["${aws_security_group.ScgMaintenance.id}"]
  associate_public_ip_address = true
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 8
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags {
    Name = "ec2-maintenance01-aza"
    Role = "maintenance"
  }
  key_name = "${var.key_pair_name}"
}

resource "aws_instance" "Ec2Ap01Aza" {
  ami           = "${var.app_instance_ec2_ami}"
  instance_type = "${var.app_instance_type}"
  availability_zone = "ap-northeast-1a"
  subnet_id     = "${aws_subnet.SbnApAza.id}"
  vpc_security_group_ids = ["${aws_security_group.ScgAp.id}"]
  associate_public_ip_address = true
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = "${var.app_instance_volume}"
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags {
    Name = "ec2-ap01-aza"
    Role = "application"
  }
  key_name = "${var.key_pair_name}"
}

resource "aws_instance" "Ec2Ap02Azc" {
  ami           = "ami-8fbab2f3"
  instance_type = "${var.app_instance_type}"
  availability_zone = "ap-northeast-1c"
  subnet_id     = "${aws_subnet.SbnApAzc.id}"
  vpc_security_group_ids = ["${aws_security_group.ScgAp.id}"]
  associate_public_ip_address = true
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = "${var.app_instance_volume}"
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags {
    Name = "ec2-ap02-azc"
  }
  key_name = "${var.key_pair_name}"
}

## Load Balaner(ALB) & Target Group & Litener

resource "aws_lb" "AlbPublic01" {
  name            = "alb-public01"
  load_balancer_type = "application"
  ip_address_type = "ipv4"
  internal        = false
  security_groups = ["${aws_security_group.ScgAlb.id}"]
  subnets         = ["${aws_subnet.SbnApAza.id}", "${aws_subnet.SbnApAzc.id}"]
}

# 「アプリサーバインスタンス」は、「SpringBootのJavaサーバアプリ」と仮定するため、
# 8080を前提としているが、対象となる「各種Webサーバ、プロダクト」にあわせて変更する。
resource "aws_lb_target_group" "TrgPublic01" {
  name     = "trg-public01"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.VpcCurrent.id}"
  health_check {
    path = "/student/index.html"
  }
}
resource "aws_lb_target_group_attachment" "TrgAtt01" {
  target_group_arn = "${aws_lb_target_group.TrgPublic01.arn}"
  target_id        = "${aws_instance.Ec2Ap01Aza.id}"
  port             = 8080
}
resource "aws_lb_target_group_attachment" "TrgAtt02" {
  target_group_arn = "${aws_lb_target_group.TrgPublic01.arn}"
  target_id        = "${aws_instance.Ec2Ap02Azc.id}"
  port             = 8080
}

resource "aws_lb_target_group" "TrgPublic02Teacher" {
  name     = "trg-public02-teacher"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.VpcCurrent.id}"
  health_check {
    path = "/teacher/index.html"
  }
}
resource "aws_lb_target_group_attachment" "TrgAtt11" {
  target_group_arn = "${aws_lb_target_group.TrgPublic02Teacher.arn}"
  target_id        = "${aws_instance.Ec2Ap01Aza.id}"
  port             = 8081
}
resource "aws_lb_target_group_attachment" "TrgAtt12" {
  target_group_arn = "${aws_lb_target_group.TrgPublic02Teacher.arn}"
  target_id        = "${aws_instance.Ec2Ap02Azc.id}"
  port             = 8081
}

resource "aws_lb_listener" "AlbListner01" {
  load_balancer_arn = "${aws_lb.AlbPublic01.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${var.certificate_arn}"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.TrgPublic01.arn}"
  }
}

resource "aws_alb_listener_rule" "AlbListnerRuleTeacherApp" {
  listener_arn  = "${aws_lb_listener.AlbListner01.arn}"
  priority      = "1"
  condition {
    field  = "path-pattern"
    values = ["/teacher*"]
  }
  action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.TrgPublic02Teacher.arn}"
  }
}

## DNS（Route53)

resource "aws_route53_record" "R53MainARecord" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.route53_record_name}"
  type    = "A"
  alias {
    name    = "${aws_lb.AlbPublic01.dns_name}"
    zone_id = "${aws_lb.AlbPublic01.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "R53MaintenanceARecord" {
  zone_id = "${var.route53_zone_id}"
  name    = "maintenance.${var.route53_record_name}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.Ec2Maintenance01Aza.public_ip}"]
}
