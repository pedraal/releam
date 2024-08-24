import gleam/uri
import releam/changelog.{type Changelog}
import releam/package_config.{type PackageConfig, Github, Repository}

pub fn generate_repository_provider_release_link(
  package_config: PackageConfig,
  new_changelog: Changelog,
) {
  case package_config.repository {
    Ok(Repository(host, org, name)) -> {
      case host {
        Github ->
          Ok(
            "https://github.com/"
            <> org
            <> "/"
            <> name
            <> "/releases/new?tag="
            <> new_changelog.title
            <> "&title="
            <> new_changelog.title
            <> "&body="
            <> uri.percent_encode(changelog.render(new_changelog, False)),
          )
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}
