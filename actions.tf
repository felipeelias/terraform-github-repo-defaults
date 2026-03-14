resource "github_actions_repository_permissions" "this" {
  repository           = github_repository.this.name
  enabled              = var.actions.enabled
  allowed_actions      = var.actions.allowed_actions
  sha_pinning_required = var.actions.sha_pinning_required

  dynamic "allowed_actions_config" {
    for_each = var.actions.allowed_actions == "selected" ? [true] : []
    content {
      github_owned_allowed = var.actions.github_owned_allowed
      verified_allowed     = var.actions.verified_allowed
      patterns_allowed     = var.actions.patterns_allowed
    }
  }
}

resource "terraform_data" "sha_pinning" {
  triggers_replace = [
    var.actions.sha_pinning_required,
    github_repository.this.name,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      gh api \
        --method PUT \
        "/repos/${github_repository.this.full_name}/actions/permissions" \
        -F enabled=true \
        -f allowed_actions=${var.actions.allowed_actions} \
        -F sha_pinning_required=${var.actions.sha_pinning_required}
    EOT
  }

  depends_on = [github_actions_repository_permissions.this]
}

resource "github_workflow_repository_permissions" "this" {
  repository                       = github_repository.this.name
  default_workflow_permissions     = var.workflow_permissions.default_workflow_permissions
  can_approve_pull_request_reviews = var.workflow_permissions.can_approve_pull_request_reviews
}
