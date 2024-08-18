import gleam/list
import gleam/regex
import gleam/string
import releam/conventional_attributes.{type ConventionalAttributes}
import releam/git

pub type Commit {
  Commit(
    hash: String,
    author: Author,
    date: String,
    conventional_attributes: ConventionalAttributes,
  )
}

pub type CommitParseError {
  InvalidCommit(String)
  InvalidConventionalAttributes(String)
}

pub type Author {
  Author(name: String, email: String)
}

pub fn parse_list(commits: List(String)) {
  commits
  |> list.map(parse_one)
}

pub fn parse_one(raw: String) {
  let assert Ok(commit_re) =
    regex.compile(
      git.git_log_commit_re,
      regex.Options(case_insensitive: False, multi_line: True),
    )

  let assert Ok(linebreaks_re) = regex.from_string("\\n\\s+\\n")

  let commit_props =
    regex.split(commit_re, raw)
    |> list.map(string.trim(_))
    |> list.map(regex.replace(linebreaks_re, _, "\n\n"))

  case commit_props {
    [_, hash, author_name, author_email, date, message, _] -> {
      let conventional_attributes =
        conventional_attributes.parse_attributes(message)

      case conventional_attributes {
        Ok(ca) ->
          Ok(Commit(
            hash: hash,
            author: Author(name: author_name, email: author_email),
            date: date,
            conventional_attributes: ca,
          ))
        Error(_) -> Error(InvalidConventionalAttributes(raw))
      }
    }
    _ -> Error(InvalidCommit(raw))
  }
}
