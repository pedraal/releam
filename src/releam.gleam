import gleam/io
import releam/commit
import releam/git

pub fn main() {
  git.get_last_tag()
  |> git.get_commits_since_last_tag
  |> commit.parse_list
  |> io.debug
}
