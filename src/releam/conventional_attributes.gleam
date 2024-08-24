import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string

pub type CommitType {
  Feat
  Perf
  Fix
  Refactor
  Docs
  Build
  Style
  Test
  Ci
  Chore
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

pub fn parse_attributes(message: String) {
  let sections =
    message
    |> string.split("\n\n")
    |> list.map(string.trim(_))

  case sections {
    [def] -> {
      def
      |> parse_definition
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
      def
      |> parse_definition
      |> result.map(fn(cd) {
        let cos = parse_optional_sections(rest)

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

pub fn parse_definition(def: String) {
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
        commit_type: parse_commit_type(commit_type),
        scope: Some(scope),
        description: description,
        breaking: is_breaking,
      ))
    [commit_type, description] ->
      Ok(ConventionalDefinition(
        commit_type: parse_commit_type(commit_type),
        scope: None,
        description: description,
        breaking: is_breaking,
      ))
    _ -> Error(InvalidCommitDefinition)
  }
}

pub fn parse_optional_sections(sections: List(String)) {
  let footer =
    sections
    |> list.last
    |> result.unwrap("")
    |> parse_footer

  let is_breaking =
    footer
    |> result.map(fn(items) {
      case list.key_find(items, "BREAKING CHANGE") {
        Ok(_) -> True
        Error(_) -> False
      }
    })
    |> result.unwrap(False)

  case list.reverse(sections), footer {
    [_, ..body], Ok(f) ->
      ConventionalOptionalSections(
        body: list.reverse(body) |> clean_body,
        footer: f,
        breaking: is_breaking,
      )
    body, Error(_) ->
      ConventionalOptionalSections(
        body: list.reverse(body) |> clean_body,
        footer: [],
        breaking: is_breaking,
      )
    _, _ ->
      ConventionalOptionalSections(body: [], footer: [], breaking: is_breaking)
  }
}

pub fn parse_footer(raw: String) {
  let assert Ok(footer_re) = regex.from_string("^[a-zA-Z0-9-]+:")
  let assert Ok(breaking_change_footer_re) =
    regex.from_string("^BREAKING CHANGE:")
  let is_footer =
    raw
    |> string.split("\n")
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
          case parse_footer_line(line) {
            Ok(fl) -> [fl, ..footer]
            Error(_) -> footer
          }
        })

      Ok(list.reverse(footer))
    }
    False -> Error(InvalidConventionalFooter)
  }
}

fn parse_footer_line(line: String) {
  case string.split(line, ":") |> list.map(string.trim(_)) {
    [key, value] -> Ok(#(key, value))
    _ -> Error(InvalidConventionalFooterLine)
  }
}

fn clean_body(lines: List(String)) {
  lines
  |> list.map(fn(line) {
    line
    |> string.split("\n")
    |> list.map(string.trim(_))
    |> string.join(" ")
  })
}

pub fn parse_commit_type(commit_type: String) {
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
    custom -> Custom(custom)
  }
}
