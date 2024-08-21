import gleamsver as gs
import gleeunit
import gleeunit/should
import releam/package_config as pc

pub fn main() {
  gleeunit.main()
}

pub fn parse_valid_test() {
  "
version = \"1.2.3\"
repository = { type = \"github\", user = \"johndoe\", repo = \"leftpad\" }
"
  |> pc.parse
  |> should.equal(pc.PackageConfig(
    gs.SemVer(1, 2, 3, "", ""),
    Ok(pc.Repository(pc.Github, "johndoe", "leftpad")),
  ))
}

pub fn parse_unsupported_repository_provider_test() {
  "
version = \"1.2.3\"
repository = { type = \"gitlab\", user = \"johndoe\", repo = \"leftpad\" }
"
  |> pc.parse
  |> should.equal(pc.PackageConfig(
    gs.SemVer(1, 2, 3, "", ""),
    Ok(pc.Repository(pc.NotImplemented("gitlab"), "johndoe", "leftpad")),
  ))
}

pub fn parse_invalid_test() {
  ""
  |> pc.parse
  |> should.equal(pc.PackageConfig(gs.SemVer(0, 0, 0, "", ""), Error(Nil)))
}
