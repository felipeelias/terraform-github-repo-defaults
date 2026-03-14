output "repository" {
  description = "Repository metadata"
  value = {
    name      = github_repository.this.name
    full_name = github_repository.this.full_name
    html_url  = github_repository.this.html_url
    ssh_url   = github_repository.this.ssh_clone_url
    http_url  = github_repository.this.http_clone_url
  }
}

output "branch_ruleset_id" {
  description = "Branch protection ruleset ID"
  value       = try(github_repository_ruleset.branch_protection[0].ruleset_id, null)
}

output "tag_ruleset_id" {
  description = "Tag protection ruleset ID"
  value       = try(github_repository_ruleset.tag_protection[0].ruleset_id, null)
}
