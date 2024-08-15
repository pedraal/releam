import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import releam.{
  Build, Chore, Ci, ConventionalAttributes, Docs, Feat, Fix,
  InvalidCommitDefinition, InvalidCommitType, InvalidConventionalFooter, Perf,
  Refactor, Revert, Style, Test,
}

pub fn main() {
  gleeunit.main()
}

// pub fn parse_conventional_attributes_simple_with_breaking_test() {
//   "feat!: send an email to the customer when a product is shipped"
//   |> releam.parse_conventional_attributes
//   |> should.equal(releam.ConventionalAttributes(
//     Some(Feat),
//     None,
//     "send an email to the customer when a product is shipped",
//     None,
//     None,
//     True,
//   ))
// }

// pub fn parse_conventional_attributes_simple_with_scope_test() {
//   "chore(deps): bump versions\n"
//   |> releam.parse_conventional_attributes
//   |> should.equal(ConventionalAttributes(
//     Some(Chore),
//     Some("deps"),
//     "bump versions",
//     None,
//     None,
//     False,
//   ))
// }

// pub fn parse_conventional_attributes_simple_with_scope_and_breaking_test() {
//   "chore(deps)!: bump versions\n"
//   |> releam.parse_conventional_attributes
//   |> should.equal(ConventionalAttributes(
//     Some(Chore),
//     Some("deps"),
//     "bump versions",
//     None,
//     None,
//     True,
//   ))
// }

// pub fn parse_conventional_attributes_with_breaking_and_breaking_footer_test() {
//   "feat(api)!: drop support for uids

//   BREAKING CHANGE: drop support for queries using uids"
//   |> releam.parse_conventional_attributes
//   |> should.equal(ConventionalAttributes(
//     Some(Feat),
//     Some("api"),
//     "drop support for uids",
//     None,
//     Some([#("BREAKING CHANGE", "drop support for queries using uids")]),
//     True,
//   ))
// }

// pub fn parse_conventional_attributes_with_bodies_test() {
//   "fix: prevent racing of requests

//   Introduce a request id and a reference to latest request. Dismiss
//   incoming responses other than from latest request.

//   Remove timeouts which were used to mitigate the racing issue but are
//   obsolete now.
//   "
//   |> releam.parse_conventional_attributes
//   |> should.equal(ConventionalAttributes(
//     Some(Fix),
//     None,
//     "prevent racing of requests",
//     Some([
//       "Introduce a request id and a reference to latest request. Dismiss\nincoming responses other than from latest request.",
//       "Remove timeouts which were used to mitigate the racing issue but are\nobsolete now.",
//     ]),
//     None,
//     False,
//   ))
// }

// pub fn parse_conventional_attributes_with_body_and_footers_test() {
//   "fix: prevent racing of requests

//   Introduce a request id and a reference to latest request. Dismiss
//   incoming responses other than from latest request.

//   Remove timeouts which were used to mitigate the racing issue but are
//   obsolete now.

//   Reviewed-by: Z
//   Refs: #123"
//   |> releam.parse_conventional_attributes
//   |> should.equal(
//     Ok(ConventionalAttributes(
//       Fix,
//       None,
//       "prevent racing of requests",
//       [
//         "Introduce a request id and a reference to latest request. Dismiss\nincoming responses other than from latest request.",
//         "Remove timeouts which were used to mitigate the racing issue but are\nobsolete now.",
//       ],
//       [#("Reviewed-by", "Z"), #("Refs", "#123")],
//       False,
//     )),
//   )
// }

pub fn parse_conventional_definition_test() {
  releam.parse_conventional_definition("feat: lorem ipsum")
  |> should.equal(
    Ok(ConventionalAttributes(
      commit_type: Feat,
      scope: None,
      message: "lorem ipsum",
      body: [],
      footer: [],
      breaking_change: False,
    )),
  )

  releam.parse_conventional_definition("feat(api): lorem ipsum")
  |> should.equal(
    Ok(ConventionalAttributes(
      commit_type: Feat,
      scope: Some("api"),
      message: "lorem ipsum",
      body: [],
      footer: [],
      breaking_change: False,
    )),
  )

  releam.parse_conventional_definition("feat(api)!: lorem ipsum")
  |> should.equal(
    Ok(ConventionalAttributes(
      commit_type: Feat,
      scope: Some("api"),
      message: "lorem ipsum",
      body: [],
      footer: [],
      breaking_change: True,
    )),
  )

  releam.parse_conventional_definition("feat!: lorem ipsum")
  |> should.equal(
    Ok(ConventionalAttributes(
      commit_type: Feat,
      scope: None,
      message: "lorem ipsum",
      body: [],
      footer: [],
      breaking_change: True,
    )),
  )

  releam.parse_conventional_definition("foo: lorem ipsum")
  |> should.equal(Error(InvalidCommitType))

  releam.parse_conventional_definition("lorem ipsum")
  |> should.equal(Error(InvalidCommitDefinition))
}

pub fn parse_conventional_optional_sections_test() {
  [
    "foo bar", "lorem ipsum",
    "Reviewed-by: Z
    Refs: #123",
  ]
  |> releam.parse_conventional_optional_sections
  |> should.equal(
    #(["foo bar", "lorem ipsum"], [#("Reviewed-by", "Z"), #("Refs", "#123")]),
  )
}

pub fn parse_conventional_optional_sections_with_invalid_footer_test() {
  ["foo bar", "lorem ipsum", "Reviewed by: Z"]
  |> releam.parse_conventional_optional_sections
  |> should.equal(#(["foo bar", "lorem ipsum", "Reviewed by: Z"], []))
}

pub fn parse_conventional_footer_test() {
  "Reviewed-by: Z
  Refs: #123"
  |> releam.parse_conventional_footer
  |> should.equal(Ok([#("Reviewed-by", "Z"), #("Refs", "#123")]))
}

pub fn parse_conventional_footer_with_breaking_change_test() {
  "Reviewed-by: Z
  BREAKING CHANGE: drop json support"
  |> releam.parse_conventional_footer
  |> should.equal(
    Ok([#("Reviewed-by", "Z"), #("BREAKING CHANGE", "drop json support")]),
  )
}

pub fn parse_conventional_footer_with_invalid_test() {
  "Reviewed by: Z"
  |> releam.parse_conventional_footer
  |> should.equal(Error(InvalidConventionalFooter))
}

pub fn parse_conventional_commit_type_test() {
  releam.parse_conventional_commit_type("feat")
  |> should.equal(Ok(Feat))

  releam.parse_conventional_commit_type("fix")
  |> should.equal(Ok(Fix))

  releam.parse_conventional_commit_type("docs")
  |> should.equal(Ok(Docs))

  releam.parse_conventional_commit_type("style")
  |> should.equal(Ok(Style))

  releam.parse_conventional_commit_type("refactor")
  |> should.equal(Ok(Refactor))

  releam.parse_conventional_commit_type("refacto")
  |> should.equal(Ok(Refactor))

  releam.parse_conventional_commit_type("perf")
  |> should.equal(Ok(Perf))

  releam.parse_conventional_commit_type("test")
  |> should.equal(Ok(Test))

  releam.parse_conventional_commit_type("tests")
  |> should.equal(Ok(Test))

  releam.parse_conventional_commit_type("build")
  |> should.equal(Ok(Build))

  releam.parse_conventional_commit_type("ci")
  |> should.equal(Ok(Ci))

  releam.parse_conventional_commit_type("chore")
  |> should.equal(Ok(Chore))

  releam.parse_conventional_commit_type("revert")
  |> should.equal(Ok(Revert))
}
