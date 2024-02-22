resource "aws_security_group" "postgresql" {
    count = var.storage.rds.enabled ? 1 : 0

    name = "${var.deploy_id}-rds-postgresql"
    description = "RDS Security Group"
    vpc_id = var.network_info.vpc_id

    lifecycle {
        create_before_destroy = true
    }
}


resource "aws_db_subnet_group" "postgresql" {
    count = var.storage.rds.enabled ? 1 : 0

    name = "postgresql"
    subnet_ids = local.private_subnet_ids
}

resource "aws_db_instance" "postgresql" {
    count = var.storage.rds.enabled ? 1 : 0

    copy_tags_to_snapshot = true

    engine = "postgres"
    engine_version = var.storage.rds.engine_version

    db_subnet_group_name = aws_db_subnet_group.postgresql[0].name
    vpc_security_group_ids = [aws_security_group.postgresql[0].id]
    instance_class = var.storage.rds.instance_class
    multi_az = var.storage.rds.multi_az
    allocated_storage = var.storage.rds.allocated_storage /* validate > 100? */

    manage_master_user_password = true
    username = "postgres"

    publicly_accessible = false
    
    auto_minor_version_upgrade = true

    deletion_protection = var.storage.rds.deletion_protection
    skip_final_snapshot = ! var.storage.rds.deletion_protection
    delete_automated_backups = ! var.storage.rds.deletion_protection
    final_snapshot_identifier = var.deploy_id
}
