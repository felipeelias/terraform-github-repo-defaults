<!-- BEGIN_TF_DOCS -->
# terraform-github-repo-defaults

Terraform module that applies opinionated security and contribution defaults to GitHub repositories. Designed to harden public repos for open source contributions while keeping them secure.

## Usage

Define your repositories in a local map and pass them to the module with `for_each`:

```hcl
locals {
  repos = {
    # Minimal — just apply secure defaults
    "my-library" = {
      description = "A reusable library"
      topics      = ["go", "library"]
    }

    # With CI status checks and custom actions
    "my-app" = {
      description = "My application"
      topics      = ["go", "docker"]

      actions = {
        patterns_allowed = [
          "golangci/golangci-lint-action@*",
          "goreleaser/goreleaser-action@*",
          "dependabot/fetch-metadata@*",
        ]
      }

      branch_protection = {
        required_status_checks = [
          { context = "test" },
          { context = "lint" },
        ]
      }
    }

    # With feature overrides
    "my-site" = {
      description  = "My website"
      homepage_url = "https://example.com"

      features = {
        has_issues     = false
        has_discussions = true
      }

      pages = {
        build_type = "workflow"
      }
    }
  }
}

module "repos" {
  source   = "github.com/felipeelias/terraform-github-repo-defaults?ref=v0.6.0"
  for_each = local.repos

  name         = each.key
  description  = try(each.value.description, null)
  homepage_url = try(each.value.homepage_url, null)
  topics       = try(each.value.topics, [])

  features          = try(each.value.features, {})
  pages             = try(each.value.pages, null)
  actions           = try(each.value.actions, {})
  branch_protection = try(each.value.branch_protection, {})
}
```

### Importing existing repositories

```hcl
import {
  to = module.repos["my-library"].github_repository.this
  id = "my-library"
}

import {
  to = module.repos["my-app"].github_repository.this
  id = "my-app"
}
```

## What this module manages

For each repository, this module configures:

- **Repository settings** — squash-only merges, auto-merge, delete branch on merge, wiki/projects off
- **Security** — secret scanning, push protection, Dependabot security updates, vulnerability alerts
- **Branch protection** — ruleset on default branch requiring PRs, signed commits, linear history
- **Tag protection** — ruleset protecting `v*` tags
- **Actions** — selected actions only (GitHub-owned + verified + explicit allowlist), SHA pinning, read-only workflow token
- **CodeQL** — enabled by default, via `gh` CLI workaround (no native Terraform resource)
- **Community health files** — `SECURITY.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 3.0), Dependabot auto-merge workflow

## Defaults

All defaults are designed to harden repositories for open source contributions while keeping them secure. Override any setting by passing the corresponding variable.

### Repository settings

| Setting | Default | Why |
|---------|---------|-----|
| `has_issues` | `true` | Primary channel for bug reports and feature requests |
| `has_wiki` | `false` | Wikis are hard to maintain and often become stale; prefer docs in the repo |
| `has_projects` | `false` | Not needed for most open source projects |
| `has_discussions` | `false` | Issues are usually sufficient; enable per-repo if needed |
| `web_commit_signoff_required` | `true` | Ensures contributors agree to DCO when editing via GitHub web UI |
| `allow_squash_merge` | `true` | Keeps history clean with one commit per PR |
| `allow_merge_commit` | `false` | Prevents noisy merge commits that clutter history |
| `allow_rebase_merge` | `false` | Avoids rewriting SHAs which breaks signature verification |
| `allow_auto_merge` | `true` | Lets maintainers approve and walk away; merges when CI passes |
| `allow_update_branch` | `true` | Contributors can update their PR branch from the GitHub UI |
| `delete_branch_on_merge` | `true` | Prevents stale branches from accumulating |
| `squash_merge_commit_title` | `PR_TITLE` | Produces readable `git log` entries from PR titles |
| `squash_merge_commit_message` | `BLANK` | Avoids dumping all PR commit messages into the squash commit body |

### Security

| Setting | Default | Why |
|---------|---------|-----|
| `vulnerability_alerts` | `true` | Get notified about known vulnerabilities in dependencies |
| `secret_scanning` | `true` | Detects accidentally committed secrets (API keys, tokens) |
| `secret_scanning_push_protection` | `true` | Blocks pushes before secrets reach the remote |
| `dependabot_security_updates` | `true` | Automates PRs to patch vulnerable dependencies |

### Branch protection (ruleset on default branch)

| Setting | Default | Why |
|---------|---------|-----|
| `require_linear_history` | `true` | Makes `git bisect` and reverts reliable |
| `require_signatures` | `true` | Verifies commit authorship; prevents impersonation |
| `required_approving_review_count` | `1` | At least one review before merging |
| `dismiss_stale_reviews_on_push` | `true` | Forces re-review when code changes after approval |
| `allowed_merge_methods` | `["squash"]` | Enforces the squash-only merge strategy at the ruleset level |
| `strict_status_checks` | `true` | PRs must be up to date with the base branch before merging |
| `bypass_actors` | Repository admin | Only admins can push directly or bypass the ruleset |

### Tag protection (ruleset on `v*` tags)

| Setting | Default | Why |
|---------|---------|-----|
| `enabled` | `true` | Prevents release tags from being deleted or overwritten |
| `tag_pattern` | `refs/tags/v*` | Covers semver release tags (`v1.0.0`, `v2.3.1`, etc.) |

### Actions

| Setting | Default | Why |
|---------|---------|-----|
| `allowed_actions` | `selected` | Only explicitly permitted actions can run; reduces supply chain risk |
| `github_owned_allowed` | `true` | GitHub-maintained actions (`actions/*`) are trusted |
| `verified_allowed` | `true` | Marketplace-verified publishers are allowed |
| `sha_pinning_required` | `true` | Prevents tag-swapping attacks on third-party actions |
| `default_workflow_permissions` | `read` | Least-privilege; workflows must explicitly request write permissions |
| `can_approve_pull_request_reviews` | `true` | Allows automated workflows (e.g., Dependabot auto-merge) to approve PRs |

### Community health files

| File | Default | Why |
|------|---------|-----|
| `SECURITY.md` | enabled | Gives reporters a clear path to disclose vulnerabilities via GitHub Security Advisories |
| `CODE_OF_CONDUCT.md` | enabled | Sets expectations for contributor behavior (Contributor Covenant 3.0) |
| Dependabot auto-merge | enabled | Reduces maintenance burden by auto-merging non-major dependency updates |

## Prerequisites

- A GitHub [fine-grained personal access token](https://github.com/settings/tokens?type=beta) with admin permissions on target repositories
- The [`gh` CLI](https://cli.github.com/) authenticated (used by CodeQL and SHA pinning workarounds)
- Repositories must already exist on GitHub — this module imports and manages them, it does not create them

## Known issues

- **Unverified commits**: Files managed via `github_repository_file` (SECURITY.md, CODE_OF_CONDUCT.md, etc.) produce unsigned commits. This is a GitHub Contents API limitation.
- **SHA pinning**: The `sha_pinning_required` attribute on `github_actions_repository_permissions` is not applied by the provider ([v6.11.x](https://github.com/integrations/terraform-provider-github)). A `terraform_data` + `gh api` workaround is included.
- **Composite actions**: GitHub Actions SHA pinning only applies to direct `uses:` references. Composite actions with internal unpinned dependencies (e.g., `actions/upload-pages-artifact` calling `actions/upload-artifact@v4`) will fail — set `sha_pinning_required = false` for affected repos.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.11 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.11.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Repository name (must already exist on GitHub) | `string` | n/a | yes |
| <a name="input_actions"></a> [actions](#input\_actions) | GitHub Actions configuration | <pre>object({<br/>    enabled              = optional(bool, true)<br/>    allowed_actions      = optional(string, "selected")<br/>    github_owned_allowed = optional(bool, true)<br/>    verified_allowed     = optional(bool, true)<br/>    patterns_allowed     = optional(list(string), [])<br/>    sha_pinning_required = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_branch_protection"></a> [branch\_protection](#input\_branch\_protection) | Branch protection ruleset configuration | <pre>object({<br/>    enabled                = optional(bool, true)<br/>    name                   = optional(string, "protect-default")<br/>    branch_pattern         = optional(string, "~DEFAULT_BRANCH")<br/>    require_linear_history = optional(bool, true)<br/>    require_signatures     = optional(bool, true)<br/>    required_status_checks = optional(list(object({<br/>      context        = string<br/>      integration_id = optional(number)<br/>    })), [])<br/>    strict_status_checks = optional(bool, true)<br/>    pull_request = optional(object({<br/>      required_approving_review_count   = optional(number, 1)<br/>      dismiss_stale_reviews_on_push     = optional(bool, true)<br/>      require_code_owner_review         = optional(bool, false)<br/>      require_last_push_approval        = optional(bool, false)<br/>      required_review_thread_resolution = optional(bool, false)<br/>      allowed_merge_methods             = optional(list(string), ["squash"])<br/>    }), {})<br/>    code_scanning = optional(object({<br/>      tool                      = optional(string, "CodeQL")<br/>      alerts_threshold          = optional(string, "errors")<br/>      security_alerts_threshold = optional(string, "high_or_higher")<br/>    }), {})<br/>    copilot_code_review = optional(object({<br/>      review_on_push             = optional(bool, false)<br/>      review_draft_pull_requests = optional(bool, false)<br/>    }), {})<br/>    bypass_actors = optional(list(object({<br/>      actor_id    = number<br/>      actor_type  = string<br/>      bypass_mode = optional(string, "always")<br/>      })), [{<br/>      actor_id    = 5<br/>      actor_type  = "RepositoryRole"<br/>      bypass_mode = "always"<br/>    }])<br/>  })</pre> | `{}` | no |
| <a name="input_code_of_conduct"></a> [code\_of\_conduct](#input\_code\_of\_conduct) | Add a CODE\_OF\_CONDUCT.md (Contributor Covenant 3.0) | <pre>object({<br/>    enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_codeql"></a> [codeql](#input\_codeql) | CodeQL default setup configuration (uses gh CLI, no native TF resource) | <pre>object({<br/>    enabled     = optional(bool, true)<br/>    query_suite = optional(string, "default")<br/>  })</pre> | `{}` | no |
| <a name="input_commit_author"></a> [commit\_author](#input\_commit\_author) | Author name for Terraform-managed file commits | `string` | `"Terraform"` | no |
| <a name="input_commit_email"></a> [commit\_email](#input\_commit\_email) | Author email for Terraform-managed file commits | `string` | `""` | no |
| <a name="input_dependabot_auto_merge"></a> [dependabot\_auto\_merge](#input\_dependabot\_auto\_merge) | Automatically create a workflow that auto-approves and auto-merges non-major Dependabot PRs | <pre>object({<br/>    enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | Repository description | `string` | `null` | no |
| <a name="input_features"></a> [features](#input\_features) | Repository feature toggles | <pre>object({<br/>    has_issues                  = optional(bool, true)<br/>    has_wiki                    = optional(bool, false)<br/>    has_projects                = optional(bool, false)<br/>    has_discussions             = optional(bool, false)<br/>    web_commit_signoff_required = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_files"></a> [files](#input\_files) | Files to manage in the repository via commits | <pre>map(object({<br/>    content             = string<br/>    commit_message      = optional(string)<br/>    branch              = optional(string)<br/>    overwrite_on_create = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_homepage_url"></a> [homepage\_url](#input\_homepage\_url) | Repository homepage URL | `string` | `null` | no |
| <a name="input_merge_strategy"></a> [merge\_strategy](#input\_merge\_strategy) | Merge strategy configuration | <pre>object({<br/>    allow_squash_merge          = optional(bool, true)<br/>    allow_merge_commit          = optional(bool, false)<br/>    allow_rebase_merge          = optional(bool, false)<br/>    allow_auto_merge            = optional(bool, true)<br/>    allow_update_branch         = optional(bool, true)<br/>    delete_branch_on_merge      = optional(bool, true)<br/>    squash_merge_commit_title   = optional(string, "PR_TITLE")<br/>    squash_merge_commit_message = optional(string, "BLANK")<br/>    merge_commit_title          = optional(string, "PR_TITLE")<br/>    merge_commit_message        = optional(string, "PR_BODY")<br/>  })</pre> | `{}` | no |
| <a name="input_pages"></a> [pages](#input\_pages) | GitHub Pages configuration | <pre>object({<br/>    build_type = optional(string, "legacy")<br/>    cname      = optional(string)<br/>    source = optional(object({<br/>      branch = string<br/>      path   = optional(string, "/")<br/>    }), { branch = "main" })<br/>  })</pre> | `null` | no |
| <a name="input_security"></a> [security](#input\_security) | Security feature toggles | <pre>object({<br/>    vulnerability_alerts            = optional(bool, true)<br/>    secret_scanning                 = optional(bool, true)<br/>    secret_scanning_push_protection = optional(bool, true)<br/>    dependabot_security_updates     = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_security_policy"></a> [security\_policy](#input\_security\_policy) | Add a SECURITY.md that directs reporters to GitHub Security Advisories | <pre>object({<br/>    enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_tag_protection"></a> [tag\_protection](#input\_tag\_protection) | Tag protection ruleset configuration | <pre>object({<br/>    enabled     = optional(bool, true)<br/>    tag_pattern = optional(string, "refs/tags/v*")<br/>  })</pre> | `{}` | no |
| <a name="input_topics"></a> [topics](#input\_topics) | Repository topics | `list(string)` | `[]` | no |
| <a name="input_visibility"></a> [visibility](#input\_visibility) | Repository visibility | `string` | `"public"` | no |
| <a name="input_workflow_permissions"></a> [workflow\_permissions](#input\_workflow\_permissions) | GitHub Actions workflow token permissions | <pre>object({<br/>    default_workflow_permissions     = optional(string, "read")<br/>    can_approve_pull_request_reviews = optional(bool, true)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_branch_ruleset_id"></a> [branch\_ruleset\_id](#output\_branch\_ruleset\_id) | Branch protection ruleset ID |
| <a name="output_repository"></a> [repository](#output\_repository) | Repository metadata |
| <a name="output_tag_ruleset_id"></a> [tag\_ruleset\_id](#output\_tag\_ruleset\_id) | Tag protection ruleset ID |
<!-- END_TF_DOCS -->