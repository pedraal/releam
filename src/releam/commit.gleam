import gleam/dict
import gleam/int
import gleam/list
import gleam/regex
import gleam/result
import gleam/string
import releam/commit_regex
import releam/conventional_attributes.{
  type CommitType, type ConventionalAttributes,
} as ca

pub type Commit {
  Commit(
    hash: String,
    short_hash: String,
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

/// Groups commits by their conventional commit type
pub fn group_by_commit_type(commits: List(Commit)) {
  let sorter = fn(ct: CommitType) {
    case ct {
      ca.Feat -> 1
      ca.Perf -> 2
      ca.Fix -> 3
      ca.Refactor -> 4
      ca.Docs -> 5
      ca.Build -> 6
      ca.Chore -> 7
      ca.Test -> 8
      ca.Style -> 9
      ca.Ci -> 10
      ca.Custom(_) -> 11
    }
  }

  commits
  |> list.group(fn(c) { c.conventional_attributes.commit_type })
  |> dict.to_list
  |> list.sort(fn(group_a, group_b) {
    int.compare(sorter(group_a.0), sorter(group_b.0))
  })
}

/// Parses a list of commits from the `git log` output to a list of Commit records
pub fn parse_list(commits: List(String)) {
  commits
  |> list.map(parse_one)
  |> list.filter(result.is_ok(_))
  |> result.all
  |> result.unwrap([])
}

/// Parses a string commit from the `git log` output to a Commit record
pub fn parse_one(raw: String) {
  let assert Ok(commit_re) =
    regex.compile(
      commit_regex.git_log_commit_re,
      regex.Options(case_insensitive: False, multi_line: True),
    )

  let assert Ok(linebreaks_re) = regex.from_string("\\n\\s+\\n")

  let commit_props =
    regex.split(commit_re, raw)
    |> list.map(string.trim(_))
    |> list.map(regex.replace(linebreaks_re, _, "\n\n"))

  case commit_props {
    [_, hash, author_name, author_email, date, message, _] -> {
      let conventional_attributes = ca.parse_attributes(message)

      case conventional_attributes {
        Ok(ca) ->
          Ok(Commit(
            hash: hash,
            short_hash: string.slice(hash, 0, 7),
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
