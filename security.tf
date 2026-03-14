resource "github_repository_dependabot_security_updates" "this" {
  count      = var.security.dependabot_security_updates ? 1 : 0
  repository = github_repository.this.name
  enabled    = true
}

resource "terraform_data" "codeql_default_setup" {
  count = var.codeql.enabled ? 1 : 0

  triggers_replace = [
    var.codeql.enabled,
    var.codeql.query_suite,
    github_repository.this.name,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      gh api \
        --method PATCH \
        "/repos/${github_repository.this.full_name}/code-scanning/default-setup" \
        -f state=configured \
        -f query_suite=${var.codeql.query_suite}
    EOT
  }
}
