import gleam/dict
import gleam/regex
import gleam/result
import gleamsver.{type SemVer}
import snag
import tom

pub type RepositoryHost {
  Github
  NotImplemented(String)
}

pub type Repository {
  Repository(host: RepositoryHost, org: String, name: String)
}

pub type PackageConfig {
  PackageConfig(
    version: SemVer,
    repository: Result(Repository, Nil),
    auto_push: Bool,
  )
}

pub type Overrides {
  Overrides(auto_push: Result(Bool, snag.Snag))
}

/// Parses the content of a gleam.toml to return a PackageConfig
pub fn parse(raw_config: String, overrides: Overrides) {
  let assert Ok(config) = tom.parse(raw_config)

  let raw_version =
    tom.get_string(config, ["version"]) |> result.unwrap("0.0.0")
  let version =
    gleamsver.parse(raw_version)
    |> result.unwrap(gleamsver.SemVer(0, 0, 0, "", ""))

  let repository_config =
    config
    |> tom.get_table(["repository"])
    |> result.unwrap(dict.new())

  let repository_host =
    repository_config
    |> tom.get_string(["type"])
    |> result.map(fn(repo_type) {
      case repo_type {
        "github" -> Github
        other -> NotImplemented(other)
      }
    })

  let repository_org = repository_config |> tom.get_string(["user"])
  let repository_name = repository_config |> tom.get_string(["repo"])

  let repository = case repository_host, repository_org, repository_name {
    Ok(rp), Ok(ro), Ok(rn) -> Ok(Repository(rp, ro, rn))
    _, _, _ -> Error(Nil)
  }

  let auto_push = case config |> tom.get_bool(["releam", "auto_push"]) {
    Ok(v) -> v
    _ -> False
  }

  let auto_push = case overrides.auto_push {
    Ok(v) -> v
    _ -> auto_push
  }

  PackageConfig(version, repository, auto_push)
}

/// Replace the package version in a gleam.toml content
pub fn replace_version(raw_config: String, new_version: gleamsver.SemVer) {
  let assert Ok(version_re) = regex.from_string("version\\s*=\\s*\"(.+)\"")
  regex.replace(
    version_re,
    raw_config,
    "version = \"" <> gleamsver.to_string(new_version) <> "\"",
  )
}
