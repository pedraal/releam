import gleam/list
import gleam/regex
import gleam/result
import gleam/string
import releam/changelog
import releam/commit_regex
import shellout

pub fn get_last_tag() {
  exec_git(["describe", "--tags", "--abbrev=0"])
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
      commit_regex.git_log_commit_re,
      regex.Options(case_insensitive: False, multi_line: True),
    )

  let output = exec_git(["log", reference]) |> result.unwrap("")

  regex.scan(re, output) |> list.map(fn(m) { m.content })
}

pub fn commit_release(new_tag: String) {
  let assert Ok(_) =
    exec_git(["add", changelog.changelog_file_path, "gleam.toml"])
  let assert Ok(_) = exec_git(["commit", "-m", "chore(release): " <> new_tag])
  let assert Ok(_) = exec_git(["tag", "-am", new_tag, new_tag])
  let assert Ok(_) = exec_git(["push", "--follow-tags"])
}

pub fn exec_git(args: List(String)) {
  shellout.command(run: "git", with: args, in: ".", opt: [])
}
