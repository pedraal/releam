import gleam/option
import gleamsver as gs
import gleeunit
import gleeunit/should
import releam/changelog as cl
import releam/commit as c
import releam/conventional_attributes as ca
import releam/package_config as pc
import releam/release

pub fn main() {
  gleeunit.main()
}

pub fn generate_repository_host_release_link_test() {
  let package_config =
    pc.PackageConfig(
      gs.SemVer(1, 0, 0, "", ""),
      Ok(pc.Repository(pc.Github, "johndoe", "blog")),
      False,
    )

  let compare_url = "https://github.com/johndoe/blog/compare/v1.0.0...v1.1.0"

  let changelog =
    cl.Changelog("v1.1.0", Ok(compare_url), [
      cl.Section(ca.Feat, [
        gen_commit(ca.Feat, option.Some("posts"), "add index endpoint"),
      ]),
    ])

  release.generate_repository_host_release_link(package_config, changelog)
  |> should.equal(Ok(
    "https://github.com/johndoe/blog/releases/new?tag=v1.1.0&title=v1.1.0&body=%5Bcompare%20changes%5D(https%3A%2F%2Fgithub.com%2Fjohndoe%2Fblog%2Fcompare%2Fv1.0.0...v1.1.0)%0A%0A%23%23%23%20%F0%9F%9A%80%20Enhancements%0A%0A-%20**posts**%3A%20Add%20index%20endpoint",
  ))
}

fn gen_commit(
  commit_type: ca.CommitType,
  scope: option.Option(String),
  description: String,
) {
  c.Commit(
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "aaaaaaa",
    c.Author("johndoe", "john@doe.com"),
    "",
    conventional_attributes: ca.ConventionalAttributes(
      commit_type,
      scope,
      description,
      [],
      [],
      False,
    ),
  )
}
