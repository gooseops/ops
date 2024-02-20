resource "helm_release" "metabase" {
    count            = var.is_metabase_enabled ? 1 : 0
    name             = "metabase"
    chart            = "https://gitlab.com/api/v4/projects/31990330/packages/generic/metabase/${var.metabase_chart_version}/metabase-${var.metabase_chart_version}.tgz"
    create_namespace = true
    namespace        = var.namespace
    repository_username = "devops"
    repository_password = var.ctx_deltacm_read_api_token

    set {
        name  = "mb_db_type"
        value = var.mb_db_type
    }

    set_sensitive {
        name  = "mb_db_dbname"
        value = var.mb_db_dbname
    }

    set_sensitive {
        name  = "mb_db_port"
        value = var.mb_db_port
    }

    set_sensitive {
        name  = "mb_db_user"
        value = var.mb_db_user
    }

    set_sensitive {
        name  = "mb_db_pass"
        value = var.mb_db_pass
    }

    set_sensitive {
        name  = "mb_db_host"
        value = var.mb_db_host
    }

    values = [
        "${fileexists("${var.deltacm_home}/kubernetes/values/metabase.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/metabase.values.yaml") : file("/dev/null")}",
        # "${fileexists("${var.deltacm_home}/kubernetes/values/metabase.metabase.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/metabase.metabase.values.yaml") : file("/dev/null")}"
    ]
}
