variable "name" {
  description = "Repository name (must already exist on GitHub)"
  type        = string
}

variable "description" {
  description = "Repository description"
  type        = string
  default     = null
}

variable "homepage_url" {
  description = "Repository homepage URL"
  type        = string
  default     = null
}

variable "topics" {
  description = "Repository topics"
  type        = list(string)
  default     = []
}

variable "visibility" {
  description = "Repository visibility"
  type        = string
  default     = "public"
}

variable "features" {
  description = "Repository feature toggles"
  type = object({
    has_issues                  = optional(bool, true)
    has_wiki                    = optional(bool, false)
    has_projects                = optional(bool, false)
    has_discussions             = optional(bool, false)
    web_commit_signoff_required = optional(bool, false)
  })
  default = {}
}

variable "merge_strategy" {
  description = "Merge strategy configuration"
  type = object({
    allow_squash_merge          = optional(bool, true)
    allow_merge_commit          = optional(bool, false)
    allow_rebase_merge          = optional(bool, false)
    allow_auto_merge            = optional(bool, true)
    delete_branch_on_merge      = optional(bool, true)
    squash_merge_commit_title   = optional(string, "PR_TITLE")
    squash_merge_commit_message = optional(string, "BLANK")
  })
  default = {}
}

variable "security" {
  description = "Security feature toggles"
  type = object({
    vulnerability_alerts            = optional(bool, true)
    secret_scanning                 = optional(bool, true)
    secret_scanning_push_protection = optional(bool, true)
    dependabot_security_updates     = optional(bool, true)
  })
  default = {}
}

variable "branch_protection" {
  description = "Branch protection ruleset configuration"
  type = object({
    enabled                = optional(bool, true)
    name                   = optional(string, "main-protection")
    branch_pattern         = optional(string, "refs/heads/main")
    require_linear_history = optional(bool, true)
    require_signatures     = optional(bool, true)
    required_status_checks = optional(list(object({
      context        = string
      integration_id = optional(number)
    })), [])
    strict_status_checks = optional(bool, true)
    pull_request = optional(object({
      required_approving_review_count   = optional(number, 1)
      dismiss_stale_reviews_on_push     = optional(bool, true)
      require_code_owner_review         = optional(bool, false)
      require_last_push_approval        = optional(bool, false)
      required_review_thread_resolution = optional(bool, false)
      allowed_merge_methods             = optional(list(string), ["squash"])
    }), {})
    code_scanning = optional(object({
      tool                      = optional(string, "CodeQL")
      alerts_threshold          = optional(string, "errors")
      security_alerts_threshold = optional(string, "high_or_higher")
    }))
    copilot_code_review = optional(object({
      review_on_push             = optional(bool, false)
      review_draft_pull_requests = optional(bool, false)
    }))
    bypass_actors = optional(list(object({
      actor_id    = number
      actor_type  = string
      bypass_mode = optional(string, "always")
      })), [{
      actor_id    = 5
      actor_type  = "RepositoryRole"
      bypass_mode = "always"
    }])
  })
  default = {}
}

variable "tag_protection" {
  description = "Tag protection ruleset configuration"
  type = object({
    enabled     = optional(bool, true)
    tag_pattern = optional(string, "refs/tags/v*")
  })
  default = {}
}

variable "actions" {
  description = "GitHub Actions configuration"
  type = object({
    enabled              = optional(bool, true)
    allowed_actions      = optional(string, "selected")
    github_owned_allowed = optional(bool, true)
    verified_allowed     = optional(bool, true)
    patterns_allowed     = optional(list(string), [])
  })
  default = {}
}

variable "workflow_permissions" {
  description = "GitHub Actions workflow token permissions"
  type = object({
    default_workflow_permissions     = optional(string, "read")
    can_approve_pull_request_reviews = optional(bool, false)
  })
  default = {}
}

variable "codeql" {
  description = "CodeQL default setup configuration (uses gh CLI, no native TF resource)"
  type = object({
    enabled     = optional(bool, false)
    query_suite = optional(string, "default")
  })
  default = {}
}

variable "files" {
  description = "Files to manage in the repository via commits"
  type = map(object({
    content             = string
    commit_message      = optional(string)
    branch              = optional(string)
    overwrite_on_create = optional(bool, true)
  }))
  default = {}
}

variable "commit_author" {
  description = "Author name for Terraform-managed file commits"
  type        = string
  default     = "Terraform"
}

variable "commit_email" {
  description = "Author email for Terraform-managed file commits"
  type        = string
  default     = ""
}
