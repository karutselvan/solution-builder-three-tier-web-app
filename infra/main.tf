module "three-tier-app-vpc-network" {
    source = "./modules/terraform-google-solution-builder-vpc-network"
    project_id = var.project_id
    region = var.region
    network_name = var.three-tier-app-vpc-network-network_name
}

module "three-tier-app-cache" {
    source = "./modules/terraform-google-solution-builder-redis"
    project_id = var.project_id
    region = var.region
    redis_instance_name = var.three-tier-app-cache-redis_instance_name
    network_name = module.three-tier-app-vpc-network.network_name
}

module "three-tier-app-database" {
    source = "./modules/terraform-google-solution-builder-cloud-sql"
    project_id = var.project_id
    region = var.region
    database_name = var.three-tier-app-database-database_name
    network_name = module.three-tier-app-vpc-network.network_name
    network_dependency = module.three-tier-app-vpc-network.module_dependency
    user_service_account_name = module.three-tier-app-backend.cloud_run_service_account_name
}

module "three-tier-app-backend" {
    source = "./modules/terraform-google-solution-builder-cloud-run"
    project_id = var.project_id
    region = var.region
    cloud_run_service_name = var.three-tier-app-backend-cloud_run_service_name
    cloud_run_service_image = var.three-tier-app-backend-cloud_run_service_image
    env_variables = {
        "CLOUD_SQL_DATABASE_HOST" = module.three-tier-app-database.database_host
        "CLOUD_SQL_DATABASE_CONNECTION_NAME" = module.three-tier-app-database.database_connection_name
        "CLOUD_SQL_DATABASE_NAME" = module.three-tier-app-database.database_name
        "REDIS_HOST" = module.three-tier-app-cache.redis_host
        "REDIS_PORT" = module.three-tier-app-cache.redis_port
    }
    dependencies = [module.three-tier-app-database.module_dependency]
    annotations = {
        "run.googleapis.com/cloudsql-instances" = module.three-tier-app-database.database_connection_name
    }
    vpc_access_connector_id = module.three-tier-app-vpc-network.vpc_access_connector_id
}

module "three-tier-app-frontend" {
    source = "./modules/terraform-google-solution-builder-cloud-run"
    project_id = var.project_id
    region = var.region
    cloud_run_service_name = var.three-tier-app-frontend-cloud_run_service_name
    cloud_run_service_image = var.three-tier-app-frontend-cloud_run_service_image
    env_variables = {
        "BACKEND_SERVICE_ENDPOINT" = module.three-tier-app-backend.cloud_run_service_endpoint
    }
    vpc_access_connector_id = var.three-tier-app-frontend-vpc_access_connector_id
}