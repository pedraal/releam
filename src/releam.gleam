import gleam/io
import gleam/option.{None, Some}
import gleamsver as gs
import releam/changelog
import releam/commit
import releam/git
import releam/package_config
import releam/release
import releam/semver
import simplifile

pub fn main() {
  let current_tag = git.get_last_tag()

  let commits =
    current_tag
    |> git.get_commits_since_last_tag
    |> commit.parse_list

  let assert Ok(raw_config) = simplifile.read("gleam.toml")
  let config = package_config.parse(raw_config)

  let bump_type = semver.define_bump_type(commits)

  let new_version = case bump_type {
    Some(semver.Major) ->
      gs.SemVer(..config.version, major: config.version.major + 1)
    Some(semver.Minor) ->
      gs.SemVer(..config.version, minor: config.version.minor + 1)
    Some(semver.Patch) ->
      gs.SemVer(..config.version, patch: config.version.patch + 1)
    None -> config.version
  }

  let new_tag = "v" <> gs.to_string(new_version)

  let new_changelog =
    changelog.new(
      config,
      changelog.ChangelogConfig(current_tag, new_tag),
      commits,
    )

  let assert Ok(_) = changelog.write_to_changelog_file(new_changelog)

  let assert Ok(_) =
    simplifile.write(
      "gleam.toml",
      package_config.replace_version(raw_config, new_version),
    )

  git.commit_release(new_tag, push: config.auto_push)

  case release.generate_repository_host_release_link(config, new_changelog) {
    Ok(rl) -> {
      io.println("Click on the following link to create a new release")
      io.println(rl)
    }
    _ -> Nil
  }
}
