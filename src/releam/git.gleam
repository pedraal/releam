import gleam/list
import gleam/regex
import gleam/result
import gleam/string

import shellout

pub const git_log_commit_re = "^commit\\s([0-9a-f]{40})$\\n^Author:\\s(.+)\\s<(.+)>$\\n^Date:\\s+(.+)$\\n\\n((?:\\s{4}.+\\n?)+)(?:\\n?(?:\\s{4}.+\\n?)+)?$"

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

  let assert Ok(re) =
    regex.compile(
      git_log_commit_re,
      regex.Options(case_insensitive: False, multi_line: True),
    )

  let output =
    shellout.command(run: "git", with: ["log", reference], in: ".", opt: [])
    |> result.unwrap("")

  regex.scan(re, output)
  |> list.map(fn(m) { m.content })
}
