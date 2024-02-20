resource "helm_release" "doppler_operator" {
    count            = var.is_doppler_operator_enabled ? 1 : 0
    name             = "doppler-operator-${var.k8s_cluster_version}"
    repository       = "https://helm.doppler.com"
    chart            = "doppler-kubernetes-operator"
    # version          = "1.2.5"
        values = [
        "${fileexists("${var.deltacm_home}/kubernetes/values/doppler-operator.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/doppler-operator.values.yaml") : file("/dev/null")}",
        # "${fileexists("${var.deltacm_home}/kubernetes/values/doppler-operator.${var.namespace}.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/doppler-operator.${var.namespace}.values.yaml") : file("/dev/null")}"
    ]
}
