import gleamsver as gs
import gleeunit
import gleeunit/should
import releam/package_config as pc
import snag

pub fn main() {
  gleeunit.main()
}

pub fn parse_valid_test() {
  "
version = \"1.2.3\"
repository = { type = \"github\", user = \"johndoe\", repo = \"leftpad\" }
[releam]
auto_push = true
"
  |> pc.parse(pc.Overrides(snag.error("")))
  |> should.equal(pc.PackageConfig(
    gs.SemVer(1, 2, 3, "", ""),
    Ok(pc.Repository(pc.Github, "johndoe", "leftpad")),
    True,
  ))
}

pub fn parse_unsupported_repository_host_test() {
  "
version = \"1.2.3\"
repository = { type = \"gitlab\", user = \"johndoe\", repo = \"leftpad\" }
[releam]
auto_push = false
"
  |> pc.parse(pc.Overrides(snag.error("")))
  |> should.equal(pc.PackageConfig(
    gs.SemVer(1, 2, 3, "", ""),
    Ok(pc.Repository(pc.NotImplemented("gitlab"), "johndoe", "leftpad")),
    False,
  ))
}

pub fn parse_invalid_test() {
  ""
  |> pc.parse(pc.Overrides(snag.error("")))
  |> should.equal(pc.PackageConfig(
    gs.SemVer(0, 0, 0, "", ""),
    Error(Nil),
    False,
  ))
}

pub fn parse_with_overrides_test() {
  "
version = \"1.0.0\"
[releam]
auto_push = false"
  |> pc.parse(pc.Overrides(Ok(True)))
  |> should.equal(pc.PackageConfig(gs.SemVer(1, 0, 0, "", ""), Error(Nil), True))

  "
version = \"1.0.0\"
[releam]
auto_push = true"
  |> pc.parse(pc.Overrides(Ok(False)))
  |> should.equal(pc.PackageConfig(
    gs.SemVer(1, 0, 0, "", ""),
    Error(Nil),
    False,
  ))
}

pub fn replace_version_test() {
  "
version = \"0.0.0\"
repository = { type = \"gitlab\", user = \"johndoe\", repo = \"leftpad\" }
"
  |> pc.replace_version(gs.SemVer(1, 2, 4, "", ""))
  |> should.equal(
    "
version = \"1.2.4\"
repository = { type = \"gitlab\", user = \"johndoe\", repo = \"leftpad\" }
",
  )
}
