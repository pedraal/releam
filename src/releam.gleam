import argv
import gleam/io
import gleam/option.{None, Some}
import gleamsver as gs
import glint
import releam/changelog
import releam/commit
import releam/git
import releam/package_config
import releam/release
import releam/semver
import simplifile

pub fn main() {
  glint.new()
  |> glint.with_name("releam")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: release())
  |> glint.run(argv.load().arguments)
}

fn push_flag() -> glint.Flag(Bool) {
  glint.bool_flag("push")
  |> glint.flag_help("Automatically push git commit and tag")
}

fn major_flag() -> glint.Flag(Bool) {
  glint.bool_flag("major")
  |> glint.flag_help("Force a major release")
}

fn minor_flag() -> glint.Flag(Bool) {
  glint.bool_flag("minor")
  |> glint.flag_help("Force a minor release")
}

fn patch_flag() -> glint.Flag(Bool) {
  glint.bool_flag("patch")
  |> glint.flag_help("Force a patch release")
}

fn release() {
  use <- glint.command_help("Generate a new release")

  use push <- glint.flag(push_flag())

  use major <- glint.flag(major_flag())
  use minor <- glint.flag(minor_flag())
  use patch <- glint.flag(patch_flag())

  use _, _, flags <- glint.command()

  let current_tag = git.get_last_tag()

  let commits =
    current_tag
    |> git.get_commits_since_last_tag
    |> commit.parse_list

  let assert Ok(raw_config) = simplifile.read("gleam.toml")
  let config =
    package_config.parse(
      raw_config,
      package_config.Overrides(auto_push: push(flags)),
    )

  let bump_type = case major(flags), minor(flags), patch(flags) {
    Ok(True), _, _ -> Some(semver.Major)
    _, Ok(True), _ -> Some(semver.Minor)
    _, _, Ok(True) -> Some(semver.Patch)
    _, _, _ -> semver.define_bump_type(commits)
  }

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
