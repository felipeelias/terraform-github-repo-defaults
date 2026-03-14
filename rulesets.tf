resource "github_repository_ruleset" "branch_protection" {
  count       = var.branch_protection.enabled ? 1 : 0
  name        = var.branch_protection.name
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = [var.branch_protection.branch_pattern]
      exclude = []
    }
  }

  dynamic "bypass_actors" {
    for_each = var.branch_protection.bypass_actors
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = var.branch_protection.require_linear_history
    required_signatures     = var.branch_protection.require_signatures

    dynamic "pull_request" {
      for_each = var.branch_protection.pull_request != null ? [var.branch_protection.pull_request] : []
      content {
        required_approving_review_count   = pull_request.value.required_approving_review_count
        dismiss_stale_reviews_on_push     = pull_request.value.dismiss_stale_reviews_on_push
        require_code_owner_review         = pull_request.value.require_code_owner_review
        require_last_push_approval        = pull_request.value.require_last_push_approval
        required_review_thread_resolution = pull_request.value.required_review_thread_resolution
      }
    }

    dynamic "required_status_checks" {
      for_each = length(var.branch_protection.required_status_checks) > 0 ? [true] : []
      content {
        strict_required_status_checks_policy = var.branch_protection.strict_status_checks

        dynamic "required_check" {
          for_each = var.branch_protection.required_status_checks
          content {
            context        = required_check.value.context
            integration_id = required_check.value.integration_id
          }
        }
      }
    }

    dynamic "required_code_scanning" {
      for_each = var.branch_protection.code_scanning != null ? [var.branch_protection.code_scanning] : []
      content {
        required_code_scanning_tool {
          tool                      = required_code_scanning.value.tool
          alerts_threshold          = required_code_scanning.value.alerts_threshold
          security_alerts_threshold = required_code_scanning.value.security_alerts_threshold
        }
      }
    }

    dynamic "copilot_code_review" {
      for_each = var.branch_protection.copilot_code_review != null ? [var.branch_protection.copilot_code_review] : []
      content {
        review_on_push             = copilot_code_review.value.review_on_push
        review_draft_pull_requests = copilot_code_review.value.review_draft_pull_requests
      }
    }
  }
}

resource "github_repository_ruleset" "tag_protection" {
  count       = var.tag_protection.enabled ? 1 : 0
  name        = "protect-tags"
  repository  = github_repository.this.name
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = [var.tag_protection.tag_pattern]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }
}
