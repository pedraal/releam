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
}

pub type ConventionalCommitParseError {
  InvalidCommitType
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
    message: String,
    body: List(String),
    footer: List(#(String, String)),
    breaking_change: Bool,
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
    |> io.debug

  case sections {
    [def] -> parse_conventional_definition(def)
    [def, ..rest] -> {
      parse_conventional_definition(def)
      |> result.map(fn(conventional_attributes) {
        let #(body, footer) = parse_conventional_optional_sections(rest)
        let is_breaking_change =
          list.any(footer, fn(item) { item.0 == "BREAKING CHANGE" })

        ConventionalAttributes(
          ..conventional_attributes,
          body: body,
          footer: footer,
          breaking_change: conventional_attributes.breaking_change
            || is_breaking_change,
        )
      })
    }
    _ -> Error(InvalidCommitMessage)
  }
}

pub fn parse_conventional_definition(def: String) {
  let is_breaking_change = string.contains(def, "!:")
  let attributes =
    def
    |> string.replace(")", "")
    |> string.replace("!:", ":")
    |> string.replace("(", ":")
    |> string.split(":")
    |> list.map(string.trim(_))

  case attributes {
    [commit_type, scope, message] ->
      parse_conventional_commit_type(commit_type)
      |> result.map(fn(c_t) {
        ConventionalAttributes(
          commit_type: c_t,
          scope: Some(scope),
          message: message,
          body: [],
          footer: [],
          breaking_change: is_breaking_change,
        )
      })
    [commit_type, message] ->
      parse_conventional_commit_type(commit_type)
      |> result.map(fn(c_t) {
        ConventionalAttributes(
          commit_type: c_t,
          scope: None,
          message: message,
          body: [],
          footer: [],
          breaking_change: is_breaking_change,
        )
      })
    _ -> Error(InvalidCommitDefinition)
  }
}

pub fn parse_conventional_optional_sections(sections: List(String)) {
  let footer =
    list.last(sections)
    |> result.unwrap("")
    |> parse_conventional_footer

  case list.reverse(sections), footer {
    [_, ..body], Ok(f) -> #(list.reverse(body), f)
    body, Error(_) -> #(list.reverse(body), [])
    _, _ -> #([], [])
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

pub fn parse_conventional_commit_type(commit_type: String) {
  case commit_type {
    "feat" -> Ok(Feat)
    "fix" -> Ok(Fix)
    "docs" -> Ok(Docs)
    "style" -> Ok(Style)
    "refactor" | "refacto" -> Ok(Refactor)
    "perf" -> Ok(Perf)
    "test" | "tests" -> Ok(Test)
    "build" -> Ok(Build)
    "ci" -> Ok(Ci)
    "chore" -> Ok(Chore)
    "revert" -> Ok(Revert)
    _ -> Error(InvalidCommitType)
  }
}
