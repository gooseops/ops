resource "random_id" "runner_name" {
    byte_length = 2
    prefix = "${var.gitlab_runner_name}-${var.k8s_cluster_version}-"
}

resource "helm_release" "gitlab_runner" {
    count            = var.is_gitlab_runner_enabled ? 1 : 0
    name             = lower(random_id.runner_name.hex)
    repository       = "https://charts.gitlab.io"
    chart            = "gitlab-runner"
    create_namespace = true
    namespace        = "gitlab"

 
    set_sensitive {
        name  = "runnerToken"
        value = var.gitlab_runner_authentication_token
    }
 
    values = [
        "${fileexists("${var.deltacm_home}/kubernetes/values/gitlab-runner.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/gitlab-runner.values.yaml") : file("/dev/null")}",
        "${fileexists("${var.deltacm_home}/kubernetes/values/gitlab-runners/runner.${var.gitlab_runner_name}.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/gitlab-runners/runner.${var.gitlab_runner_name}.values.yaml") : file("/dev/null")}"
    ]
}
