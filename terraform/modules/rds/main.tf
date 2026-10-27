# Create a subnet group so RDS can use the private subnets.
resource "aws_db_subnet_group" "this" {
  name        = "${var.identifier}-subnets"
  description = "Private subnets for the Bagisto database"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnets"
  })
}

# Permit MySQL traffic only from explicitly approved security groups.
resource "aws_security_group" "database" {
  name        = "${var.identifier}-database"
  description = "Restricted access to the Bagisto MySQL database"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids

    content {
      description     = "MySQL access from an approved application security group"
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # Permit outbound traffic for database-managed operations.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.identifier}-database"
  })
}

# Create a Secrets Manager container for the database credentials.
# The actual password will be generated and managed separately.
resource "aws_secretsmanager_secret" "credentials" {
  name                    = "${var.identifier}/database-credentials"
  description             = "Credentials for the Bagisto RDS database"
  recovery_window_in_days = 7

  tags = var.tags
}

# Create the private MySQL database.
resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username

  # Let RDS generate and manage the master password in Secrets Manager.
  manage_master_user_password = true

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]

  publicly_accessible = false
  multi_az            = var.multi_az

  backup_retention_period = 7
  copy_tags_to_snapshot   = true
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = var.identifier
  })
}
