resource "helm_release" "gitlab_cluster_agent" {
    count            = var.is_gitlab_cluster_agent_enabled ? 1 : 0
    name             = "gitlab-agent-${var.k8s_cluster_version}"
    repository       = "https://charts.gitlab.io"
    chart            = "gitlab-agent"
    create_namespace = true
    namespace        = "gitlab"

    set {
        name  = "certmanager.install"
        value = "false"
    }

    set {
        name  = "config.token"
        value = var.gitlab_agent_token
    }

    values = [
        "${fileexists("${var.deltacm_home}/kubernetes/values/gitlab-agent-delta.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/gitlab-agent-delta.values.yaml") : file("/dev/null")}",
        # "${fileexists("${var.deltacm_home}/kubernetes/values/gitlab-agent-delta.${var.namespace}.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/gitlab-agent-delta.${var.namespace}.values.yaml") : file("/dev/null")}"
    ]
}
