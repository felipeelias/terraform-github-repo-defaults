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
