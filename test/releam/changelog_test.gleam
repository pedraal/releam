import gleam/option
import gleamsver as gs
import gleeunit
import gleeunit/should
import releam/changelog as cl
import releam/commit as c
import releam/conventional_attributes as ca
import releam/package_config as pc

pub fn main() {
  gleeunit.main()
}

pub fn new_with_repository_test() {
  let package_config =
    pc.PackageConfig(
      gs.SemVer(1, 0, 0, "", ""),
      Ok(pc.Repository(pc.Github, "johndoe", "blog")),
    )
  let changelog_config = cl.ChangelogConfig("v1.0.0", "v1.1.0")

  let chore_commit = gen_commit(ca.Chore, option.None, "bump deps")
  let fix_commit =
    gen_commit(ca.Fix, option.Some("auth"), "oauth github provider")
  let feat_commit_one =
    gen_commit(ca.Feat, option.Some("posts"), "add index endpoint")
  let feat_commit_two =
    gen_commit(ca.Feat, option.Some("posts"), "add new endpoint")

  let commits = [chore_commit, feat_commit_two, fix_commit, feat_commit_one]

  cl.new(package_config, changelog_config, commits)
  |> should.equal(
    cl.Changelog(
      "v1.1.0",
      Ok("https://github.com/johndoe/blog/compare/v1.0.0...v1.1.0"),
      [
        cl.Section(ca.Feat, [feat_commit_one, feat_commit_two]),
        cl.Section(ca.Fix, [fix_commit]),
        cl.Section(ca.Chore, [chore_commit]),
      ],
    ),
  )
}

pub fn new_without_repository_test() {
  let package_config =
    pc.PackageConfig(
      gs.SemVer(1, 0, 0, "", ""),
      Ok(pc.Repository(pc.NotImplemented(""), "johndoe", "blog")),
    )
  let changelog_config = cl.ChangelogConfig("v1.0.0", "v1.1.0")

  let chore_commit = gen_commit(ca.Chore, option.None, "bump deps")

  let commits = [chore_commit]

  cl.new(package_config, changelog_config, commits)
  |> should.equal(
    cl.Changelog("v1.1.0", Error(Nil), [cl.Section(ca.Chore, [chore_commit])]),
  )
}

pub fn render_with_title_and_repository_test() {
  let chore_commit = gen_commit(ca.Chore, option.None, "bump deps")
  let fix_commit =
    gen_commit(ca.Fix, option.Some("auth"), "oauth github provider")
  let feat_commit_one =
    gen_commit(ca.Feat, option.Some("posts"), "add index endpoint")
  let feat_commit_two =
    gen_commit(ca.Feat, option.Some("posts"), "add new endpoint")

  let compare_url = "https://github.com/johndoe/blog/compare/v1.0.0...v1.1.0"
  cl.Changelog("v1.1.0", Ok(compare_url), [
    cl.Section(ca.Feat, [feat_commit_one, feat_commit_two]),
    cl.Section(ca.Fix, [fix_commit]),
    cl.Section(ca.Chore, [chore_commit]),
  ])
  |> cl.render(True)
  |> should.equal(
    "## v1.1.0\n\n[compare changes]("
    <> compare_url
    <> ")\n\n### 🚀 Enhancements\n\n- **posts**: Add index endpoint\n- **posts**: Add new endpoint\n\n### 🩹 Fixes\n\n- **auth**: Oauth github provider\n\n### 🧹 Chore\n\n- Bump deps",
  )
}

pub fn render_without_title_and_repository_test() {
  let chore_commit = gen_commit(ca.Chore, option.None, "bump deps")
  let fix_commit =
    gen_commit(ca.Fix, option.Some("auth"), "oauth github provider")
  let feat_commit_one =
    gen_commit(ca.Feat, option.Some("posts"), "add index endpoint")
  let feat_commit_two =
    gen_commit(ca.Feat, option.Some("posts"), "add new endpoint")

  cl.Changelog("v1.1.0", Error(Nil), [
    cl.Section(ca.Feat, [feat_commit_one, feat_commit_two]),
    cl.Section(ca.Fix, [fix_commit]),
    cl.Section(ca.Chore, [chore_commit]),
  ])
  |> cl.render(False)
  |> should.equal(
    "### 🚀 Enhancements\n\n- **posts**: Add index endpoint\n- **posts**: Add new endpoint\n\n### 🩹 Fixes\n\n- **auth**: Oauth github provider\n\n### 🧹 Chore\n\n- Bump deps",
  )
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
