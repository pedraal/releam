import gleam/dict
import gleam/result
import gleamsver.{type SemVer}
import tom

pub type RepositoryProvider {
  Github
  NotImplemented(String)
}

pub type Repository {
  Repository(provider: RepositoryProvider, org: String, name: String)
}

pub type PackageConfig {
  PackageConfig(version: SemVer, repository: Result(Repository, Nil))
}

pub fn parse(raw: String) {
  let assert Ok(config) = tom.parse(raw)

  let raw_version =
    tom.get_string(config, ["version"]) |> result.unwrap("0.0.0")
  let version =
    gleamsver.parse(raw_version)
    |> result.unwrap(gleamsver.SemVer(0, 0, 0, "", ""))

  let repository_config =
    config
    |> tom.get_table(["repository"])
    |> result.unwrap(dict.new())

  let repository_provider =
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

  let repository = case repository_provider, repository_org, repository_name {
    Ok(rp), Ok(ro), Ok(rn) -> Ok(Repository(rp, ro, rn))
    _, _, _ -> Error(Nil)
  }

  PackageConfig(version, repository)
}
