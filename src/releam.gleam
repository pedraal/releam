import gleam/io
import gleam/option.{None, Some}
import gleamsver as gs
import releam/changelog
import releam/commit
import releam/git
import releam/package_config
import releam/semver
import simplifile

pub fn main() {
  let current_tag = git.get_last_tag()

  let commits =
    current_tag
    |> git.get_commits_since_last_tag
    |> commit.parse_list

  let assert Ok(raw_config) = simplifile.read("gleam.toml")
  let package = package_config.parse(raw_config)

  let bump_type = semver.define_bump_type(commits)

  let new_version = case bump_type {
    Some(semver.Major) ->
      gs.SemVer(..package.version, major: package.version.major + 1)
    Some(semver.Minor) ->
      gs.SemVer(..package.version, minor: package.version.minor + 1)
    Some(semver.Patch) ->
      gs.SemVer(..package.version, patch: package.version.patch + 1)
    None -> package.version
  }

  let new_tag = "v" <> gs.to_string(new_version)

  let new_changelog =
    changelog.new(
      package,
      changelog.ChangelogConfig(current_tag, new_tag),
      commits,
    )

  let assert Ok(_) = changelog.write_to_changelog_file(new_changelog)

  // let assert Ok(_) = git.commit_release(new_tag)

  io.println("Changelog:")
  changelog.render(new_changelog, False)
  |> io.debug
}
