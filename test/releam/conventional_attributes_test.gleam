import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import releam/conventional_attributes.{
  Build, Chore, Ci, ConventionalAttributes, ConventionalDefinition,
  ConventionalOptionalSections, Custom, Docs, Feat, Fix, InvalidCommitDefinition,
  InvalidConventionalFooter, Perf, Refactor, Style, Test,
}

pub fn main() {
  gleeunit.main()
}

pub fn parse_attributes_simple_with_breaking_test() {
  "feat!: send an email to the customer when a product is shipped"
  |> conventional_attributes.parse_attributes
  |> should.equal(
    Ok(ConventionalAttributes(
      Feat,
      None,
      "send an email to the customer when a product is shipped",
      [],
      [],
      True,
    )),
  )
}

pub fn parse_attributes_simple_with_scope_test() {
  "chore(deps): bump versions\n"
  |> conventional_attributes.parse_attributes
  |> should.equal(
    Ok(ConventionalAttributes(
      Chore,
      Some("deps"),
      "bump versions",
      [],
      [],
      False,
    )),
  )
}

pub fn parse_attributes_simple_with_scope_and_breaking_test() {
  "chore(deps)!: bump versions\n"
  |> conventional_attributes.parse_attributes
  |> should.equal(
    Ok(ConventionalAttributes(
      Chore,
      Some("deps"),
      "bump versions",
      [],
      [],
      True,
    )),
  )
}

pub fn parse_attributes_with_breaking_and_breaking_footer_test() {
  "feat(api)!: drop support for uids

  BREAKING CHANGE: drop support for queries using uids"
  |> conventional_attributes.parse_attributes
  |> should.equal(
    Ok(ConventionalAttributes(
      Feat,
      Some("api"),
      "drop support for uids",
      [],
      [#("BREAKING CHANGE", "drop support for queries using uids")],
      True,
    )),
  )
}

pub fn parse_attributes_with_bodies_test() {
  "fix: prevent racing of requests

  Introduce a request id and a reference to latest request. Dismiss
  incoming responses other than from latest request.

  Remove timeouts which were used to mitigate the racing issue but are
  obsolete now.
  "
  |> conventional_attributes.parse_attributes
  |> should.equal(
    Ok(ConventionalAttributes(
      Fix,
      None,
      "prevent racing of requests",
      [
        "Introduce a request id and a reference to latest request. Dismiss incoming responses other than from latest request.",
        "Remove timeouts which were used to mitigate the racing issue but are obsolete now.",
      ],
      [],
      False,
    )),
  )
}

pub fn parse_attributes_with_body_and_footers_test() {
  "fix: prevent racing of requests

  Introduce a request id and a reference to latest request. Dismiss
  incoming responses other than from latest request.

  Remove timeouts which were used to mitigate the racing issue but are
  obsolete now.

  Reviewed-by: Z
  Refs: #123"
  |> conventional_attributes.parse_attributes
  |> should.equal(
    Ok(ConventionalAttributes(
      Fix,
      None,
      "prevent racing of requests",
      [
        "Introduce a request id and a reference to latest request. Dismiss incoming responses other than from latest request.",
        "Remove timeouts which were used to mitigate the racing issue but are obsolete now.",
      ],
      [#("Reviewed-by", "Z"), #("Refs", "#123")],
      False,
    )),
  )
}

pub fn parse_definition_test() {
  conventional_attributes.parse_definition("feat: lorem ipsum")
  |> should.equal(
    Ok(ConventionalDefinition(
      commit_type: Feat,
      scope: None,
      description: "lorem ipsum",
      breaking: False,
    )),
  )

  conventional_attributes.parse_definition("feat(api): lorem ipsum")
  |> should.equal(
    Ok(ConventionalDefinition(
      commit_type: Feat,
      scope: Some("api"),
      description: "lorem ipsum",
      breaking: False,
    )),
  )

  conventional_attributes.parse_definition("feat(api)!: lorem ipsum")
  |> should.equal(
    Ok(ConventionalDefinition(
      commit_type: Feat,
      scope: Some("api"),
      description: "lorem ipsum",
      breaking: True,
    )),
  )

  conventional_attributes.parse_definition("feat!: lorem ipsum")
  |> should.equal(
    Ok(ConventionalDefinition(
      commit_type: Feat,
      scope: None,
      description: "lorem ipsum",
      breaking: True,
    )),
  )

  conventional_attributes.parse_definition("foo: lorem ipsum")
  |> should.equal(
    Ok(ConventionalDefinition(
      commit_type: Custom("foo"),
      scope: None,
      description: "lorem ipsum",
      breaking: False,
    )),
  )

  conventional_attributes.parse_definition("lorem ipsum")
  |> should.equal(Error(InvalidCommitDefinition))
}

pub fn parse_optional_sections_test() {
  [
    "foo bar
    baz", "lorem ipsum",
    "Reviewed-by: Z
    Refs: #123
    BREAKING CHANGE: drop json support",
  ]
  |> conventional_attributes.parse_optional_sections
  |> should.equal(ConventionalOptionalSections(
    body: ["foo bar baz", "lorem ipsum"],
    footer: [
      #("Reviewed-by", "Z"),
      #("Refs", "#123"),
      #("BREAKING CHANGE", "drop json support"),
    ],
    breaking: True,
  ))
}

pub fn parse_optional_sections_with_invalid_footer_test() {
  ["foo bar", "lorem ipsum", "Reviewed by: Z"]
  |> conventional_attributes.parse_optional_sections
  |> should.equal(ConventionalOptionalSections(
    body: ["foo bar", "lorem ipsum", "Reviewed by: Z"],
    footer: [],
    breaking: False,
  ))
}

pub fn parse_footer_test() {
  "Reviewed-by: Z
  Refs: #123"
  |> conventional_attributes.parse_footer
  |> should.equal(Ok([#("Reviewed-by", "Z"), #("Refs", "#123")]))
}

pub fn parse_footer_with_breaking_change_test() {
  "Reviewed-by: Z
  BREAKING CHANGE: drop json support"
  |> conventional_attributes.parse_footer
  |> should.equal(
    Ok([#("Reviewed-by", "Z"), #("BREAKING CHANGE", "drop json support")]),
  )
}

pub fn parse_footer_with_invalid_test() {
  "Reviewed by: Z"
  |> conventional_attributes.parse_footer
  |> should.equal(Error(InvalidConventionalFooter))
}

pub fn parse_commit_type_test() {
  conventional_attributes.parse_commit_type("feat")
  |> should.equal(Feat)

  conventional_attributes.parse_commit_type("fix")
  |> should.equal(Fix)

  conventional_attributes.parse_commit_type("docs")
  |> should.equal(Docs)

  conventional_attributes.parse_commit_type("style")
  |> should.equal(Style)

  conventional_attributes.parse_commit_type("refactor")
  |> should.equal(Refactor)

  conventional_attributes.parse_commit_type("refacto")
  |> should.equal(Refactor)

  conventional_attributes.parse_commit_type("perf")
  |> should.equal(Perf)

  conventional_attributes.parse_commit_type("test")
  |> should.equal(Test)

  conventional_attributes.parse_commit_type("tests")
  |> should.equal(Test)

  conventional_attributes.parse_commit_type("build")
  |> should.equal(Build)

  conventional_attributes.parse_commit_type("ci")
  |> should.equal(Ci)

  conventional_attributes.parse_commit_type("chore")
  |> should.equal(Chore)

  conventional_attributes.parse_commit_type("whatever")
  |> should.equal(Custom("whatever"))
}
