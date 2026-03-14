resource "github_repository_file" "security_policy" {
  count               = var.security_policy.enabled ? 1 : 0
  repository          = github_repository.this.name
  file                = "SECURITY.md"
  content             = templatefile("${path.module}/files/SECURITY.md", { full_name = github_repository.this.full_name })
  commit_message      = "docs: add security policy"
  overwrite_on_create = true
  commit_author       = var.commit_author
  commit_email        = var.commit_email
}

resource "github_repository_file" "dependabot_auto_merge" {
  count               = var.dependabot_auto_merge.enabled ? 1 : 0
  repository          = github_repository.this.name
  file                = ".github/workflows/dependabot-auto-merge.yml"
  content             = file("${path.module}/files/dependabot-auto-merge.yml")
  commit_message      = "ci: add dependabot auto-merge workflow"
  overwrite_on_create = true
  commit_author       = var.commit_author
  commit_email        = var.commit_email
}

resource "github_repository_file" "managed" {
  for_each            = var.files
  repository          = github_repository.this.name
  file                = each.key
  content             = each.value.content
  commit_message      = each.value.commit_message != null ? each.value.commit_message : "chore: update ${each.key}"
  branch              = each.value.branch
  overwrite_on_create = each.value.overwrite_on_create
  commit_author       = var.commit_author
  commit_email        = var.commit_email
}
