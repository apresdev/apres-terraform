locals {
  team_definitions = {
    for fn in fileset(var.team_directory, "*.yaml") :
    # Convert to kebab-case as per recommended naming conventions
    # Resulting structure example:
    # {
    #   team1 = {
    #      description = "Team 1",
    #      name = "team1",
    #      privacy = "closed",
    #      members = [
    #       { username = "user1", role = "maintainer" },
    #       { username = "user2", role = "member" }
    #     ]
    #   },
    #   team2 = { ... etc }
    # }
    lower(
      replace(
        substr(fn, 0, length(fn) - 5),
        "/[ ._]/",
        "-"
      )
    ) =>
    yamldecode(
      file("${var.team_directory}/${fn}")
    )
  }

  # Create a list of members of teams from the definition. Resulting data structure:
  # [
  #   { team = "team1", member = "user1", role = "maintainer" },
  #   { team = "team1", member = "user2", role = "member" }
  # ]
  team_members = flatten([
    for team, team_definition in local.team_definitions : [
      for member in try(team_definition.members, []) : {
        team   = team
        member = member.username
        role   = member.role
      }
    ]
  ])

  # Create a list of members (users), without teams, resulting data structure example
  # [
  #  { username = "user1", role = "member" },
  #  { username = "user2", role = "admin" }
  # ]
  member_definitions = flatten([
    for filename in fileset(var.member_directory, "*.yaml") :
    yamldecode(file("${var.member_directory}/${filename}"))
  ])

  # Convert member_definitions into a map, resulting data structure example:
  # {
  #  "user1" = { role = "member" },
  #  "user2" = { role = "admin" }
  # }
  members = tomap({
    for user in local.member_definitions :
    user.username => { role = user.role }
  })
}

# Create the teams. Do it with an embedded module so that we can reference the team by name
# since we need the id or slug, and they aren't available until after we create the team
module "teams" {
  source       = "./modules/teams"
  for_each     = local.team_definitions
  github_owner = var.github_owner
  name         = each.value.name
  description  = each.value.description
  privacy      = each.value.privacy
}

# Add/invite members to the org. This will send email invites! Use a for_each
# loop so that if we delete a user from the list it doesn't cause a delete/create
# of the remaining users.
resource "github_membership" "members" {
  for_each = toset(keys(local.members))
  username = each.key
  role     = local.members[each.key].role
}

# Add members to the teams. Use the for_each instead of count so that
# if we remove a user/team we don't rebuild the world
resource "github_team_membership" "default" {
  for_each = {
    for tm in local.team_members : "${tm.member}-${tm.team}" => tm
  }
  # Lookup the team id (slug) from the module output
  team_id  = module.teams[each.value.team].id
  username = each.value.member
  role     = each.value.role
}

