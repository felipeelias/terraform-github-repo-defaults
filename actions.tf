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

resource "github_workflow_repository_permissions" "this" {
  repository                       = github_repository.this.name
  default_workflow_permissions     = var.workflow_permissions.default_workflow_permissions
  can_approve_pull_request_reviews = var.workflow_permissions.can_approve_pull_request_reviews
}
