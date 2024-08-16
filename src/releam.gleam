import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string
import shellout

pub type CommitType {
  Feat
  Fix
  Docs
  Style
  Refactor
  Perf
  Test
  Build
  Ci
  Chore
  Revert
  Custom(String)
}

pub type ConventionalCommitParseError {
  InvalidCommitDefinition
  InvalidCommitMessage
}

pub type ConventionalFooterParseError {
  InvalidConventionalFooter
  InvalidConventionalFooterLine
}

pub type Commit {
  Commit(
    hash: String,
    author: Author,
    date: String,
    conventional_attributes: Result(
      ConventionalAttributes,
      ConventionalCommitParseError,
    ),
  )
}

pub type ConventionalAttributes {
  ConventionalAttributes(
    commit_type: CommitType,
    scope: Option(String),
    description: String,
    body: List(String),
    footer: List(#(String, String)),
    breaking: Bool,
  )
}

pub type ConventionalDefinition {
  ConventionalDefinition(
    commit_type: CommitType,
    scope: Option(String),
    description: String,
    breaking: Bool,
  )
}

pub type ConventionalOptionalSections {
  ConventionalOptionalSections(
    body: List(String),
    footer: List(#(String, String)),
    breaking: Bool,
  )
}

pub type Author {
  Author(name: String, email: String)
}

pub fn main() {
  get_last_tag()
  |> get_commits_since_last_tag
  |> parse_commits
  |> io.debug
}

pub fn get_last_tag() {
  shellout.command(
    run: "git",
    with: ["describe", "--tags", "--abbrev=0"],
    in: ".",
    opt: [],
  )
  |> result.unwrap("")
  |> string.replace("\n", "")
}

pub fn get_commits_since_last_tag(tag: String) {
  let reference = case tag {
    "" -> "HEAD"
    t -> t <> "..HEAD"
  }

  shellout.command(run: "git", with: ["log", reference], in: ".", opt: [])
  |> result.unwrap("")
  |> string.split("\ncommit ")
  |> list.map(string.replace(_, "commit ", ""))
}

pub fn parse_commits(commits: List(String)) {
  list.map(commits, parse_commit)
  |> list.filter(fn(res) { result.is_ok(res) })
  |> list.map(result.unwrap(_, Commit(
    hash: "",
    author: Author(name: "", email: ""),
    date: "",
    conventional_attributes: Error(InvalidCommitDefinition),
  )))
}

pub fn parse_commit(raw: String) {
  let commit_props =
    raw
    |> string.replace("\n\n", "\n")
    |> string.split("\n")
    |> list.map(string.trim(_))
    |> list.filter(fn(str) { str != "" })
  case commit_props {
    // [hash, author, date, message, ..bodies] -> {
    //   let conventional_attributes = parse_conventional_attributes(message)
    //   Ok(Commit(
    //     hash: hash,
    //     author: parse_commit_author(author),
    //     date: parse_commit_date(date),
    //     conventional_attributes: conventional_attributes,
    //   ))
    // }
    _ -> Error(Nil)
  }
}

pub fn parse_commit_author(raw: String) {
  let author_props =
    string.replace(raw, "Author:", "")
    |> string.trim
    |> string.replace(">", "")
    |> string.split(" <")

  case author_props {
    [name, email] -> Author(name: name, email: email)
    _ -> Author(name: "", email: "")
  }
}

pub fn parse_commit_date(raw: String) {
  string.replace(raw, "Date:", "")
  |> string.trim
}

pub fn parse_conventional_attributes(message: String) {
  let sections =
    message
    |> string.split("\n\n")
    |> list.map(string.trim(_))

  case sections {
    [def] -> {
      parse_conventional_definition(def)
      |> result.map(fn(cd) {
        ConventionalAttributes(
          commit_type: cd.commit_type,
          scope: cd.scope,
          description: cd.description,
          body: [],
          footer: [],
          breaking: cd.breaking,
        )
      })
    }
    [def, ..rest] -> {
      parse_conventional_definition(def)
      |> result.map(fn(cd) {
        let cos = parse_conventional_optional_sections(rest)

        ConventionalAttributes(
          commit_type: cd.commit_type,
          scope: cd.scope,
          description: cd.description,
          body: cos.body,
          footer: cos.footer,
          breaking: cd.breaking || cos.breaking,
        )
      })
    }
    _ -> Error(InvalidCommitMessage)
  }
}

pub fn parse_conventional_definition(def: String) {
  let is_breaking = string.contains(def, "!:")
  let attributes =
    def
    |> string.replace(")", "")
    |> string.replace("!:", ":")
    |> string.replace("(", ":")
    |> string.split(":")
    |> list.map(string.trim(_))

  case attributes {
    [commit_type, scope, description] ->
      Ok(ConventionalDefinition(
        commit_type: parse_conventional_commit_type(commit_type),
        scope: Some(scope),
        description: description,
        breaking: is_breaking,
      ))
    [commit_type, description] ->
      Ok(ConventionalDefinition(
        commit_type: parse_conventional_commit_type(commit_type),
        scope: None,
        description: description,
        breaking: is_breaking,
      ))
    _ -> Error(InvalidCommitDefinition)
  }
}

pub fn parse_conventional_optional_sections(sections: List(String)) {
  let footer =
    list.last(sections)
    |> result.unwrap("")
    |> parse_conventional_footer

  let is_breaking =
    result.map(footer, fn(items) {
      case list.key_find(items, "BREAKING CHANGE") {
        Ok(_) -> True
        Error(_) -> False
      }
    })
    |> result.unwrap(False)

  case list.reverse(sections), footer {
    [_, ..body], Ok(f) ->
      ConventionalOptionalSections(
        body: list.reverse(body) |> clean_conventional_body,
        footer: f,
        breaking: is_breaking,
      )
    body, Error(_) ->
      ConventionalOptionalSections(
        body: list.reverse(body) |> clean_conventional_body,
        footer: [],
        breaking: is_breaking,
      )
    _, _ ->
      ConventionalOptionalSections(body: [], footer: [], breaking: is_breaking)
  }
}

pub fn parse_conventional_footer(raw: String) {
  let assert Ok(footer_re) = regex.from_string("^[a-zA-Z0-9-]+:")
  let assert Ok(breaking_change_footer_re) =
    regex.from_string("^BREAKING CHANGE:")
  let is_footer =
    string.split(raw, "\n")
    |> list.map(string.trim(_))
    |> list.all(fn(line) {
      regex.check(footer_re, line)
      || regex.check(breaking_change_footer_re, line)
    })

  case is_footer {
    True -> {
      let footer =
        raw
        |> string.split("\n")
        |> list.fold([], fn(footer, line) {
          case parse_conventional_footer_line(line) {
            Ok(fl) -> [fl, ..footer]
            Error(_) -> footer
          }
        })

      Ok(list.reverse(footer))
    }
    False -> Error(InvalidConventionalFooter)
  }
}

pub fn parse_conventional_footer_line(line: String) {
  case string.split(line, ":") |> list.map(string.trim(_)) {
    [key, value] -> Ok(#(key, value))
    _ -> Error(InvalidConventionalFooterLine)
  }
}

pub fn clean_conventional_body(lines: List(String)) {
  lines
  |> list.map(fn(line) {
    line
    |> string.split("\n")
    |> list.map(string.trim(_))
    |> string.join(" ")
  })
}

pub fn parse_conventional_commit_type(commit_type: String) {
  case commit_type {
    "feat" -> Feat
    "fix" -> Fix
    "docs" -> Docs
    "style" -> Style
    "refactor" | "refacto" -> Refactor
    "perf" -> Perf
    "test" | "tests" -> Test
    "build" -> Build
    "ci" -> Ci
    "chore" -> Chore
    "revert" -> Revert
    custom -> Custom(custom)
  }
}
