import gleam/io
import gleam/list
import gleam/result
import gleam/string
import releam/conventional_attributes.{
  type ConventionalAttributes, type ConventionalCommitParseError,
  InvalidCommitDefinition,
}
import shellout

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
  commits
  |> list.map(parse_commit)
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
    |> io.debug
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
    raw
    |> string.replace("Author:", "")
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
