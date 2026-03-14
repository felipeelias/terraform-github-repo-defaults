resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = var.homepage_url
  topics       = var.topics
  visibility   = var.visibility

  has_issues                  = var.features.has_issues
  has_wiki                    = var.features.has_wiki
  has_projects                = var.features.has_projects
  has_discussions             = var.features.has_discussions
  web_commit_signoff_required = var.features.web_commit_signoff_required

  allow_squash_merge          = var.merge_strategy.allow_squash_merge
  allow_merge_commit          = var.merge_strategy.allow_merge_commit
  allow_rebase_merge          = var.merge_strategy.allow_rebase_merge
  allow_auto_merge            = var.merge_strategy.allow_auto_merge
  allow_update_branch         = var.merge_strategy.allow_update_branch
  delete_branch_on_merge      = var.merge_strategy.delete_branch_on_merge
  squash_merge_commit_title   = var.merge_strategy.squash_merge_commit_title
  squash_merge_commit_message = var.merge_strategy.squash_merge_commit_message

  vulnerability_alerts = var.security.vulnerability_alerts

  security_and_analysis {
    secret_scanning {
      status = var.security.secret_scanning ? "enabled" : "disabled"
    }
    secret_scanning_push_protection {
      status = var.security.secret_scanning_push_protection ? "enabled" : "disabled"
    }
  }

  archive_on_destroy = true

  dynamic "pages" {
    for_each = var.pages != null ? [var.pages] : []
    content {
      build_type = pages.value.build_type
      cname      = pages.value.cname
      source {
        branch = pages.value.source.branch
        path   = pages.value.source.path
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
