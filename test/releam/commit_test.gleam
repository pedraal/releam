import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import releam/commit.{Author, Commit}
import releam/conventional_attributes as ca

pub fn main() {
  gleeunit.main()
}

const valid_commit_one = "commit aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
Author: johndoe <john@doe.com>
Date:   Fri Aug 16 01:24:47 2024 +0200

    chore(api)!: drop graphql endpoint

    api requests should now use REST /api/v1
    endpoint

    Refs: #123
"

const valid_commit_two = "commit bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
Author: janedoe <jane@doe.com>
Date:   Fri Aug 16 01:24:47 2024 +0200

    feat: update homepage styles
"

const invalid_commit_one = "commit cccccccccccccccccccccccccccccccccccccccc
Date:   Fri Aug 16 01:24:47 2024 +0200

    chore(api)!: drop graphql endpoint

    api requests should now use REST /api/v1
    endpoint

    Refs: #123
"

const invalid_commit_two = "commit dddddddddddddddddddddddddddddddddddddddd
Author: johndoe <john@doe.com>
Date:   Fri Aug 16 01:24:47 2024 +0200

    drop graphql endpoint

    api requests should now use REST /api/v1
    endpoint

    Refs: #123
"

pub fn parse_one_test() {
  valid_commit_one
  |> commit.parse_one
  |> should.equal(
    Ok(Commit(
      hash: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      author: Author(name: "johndoe", email: "john@doe.com"),
      date: "Fri Aug 16 01:24:47 2024 +0200",
      conventional_attributes: ca.ConventionalAttributes(
        ca.Chore,
        Some("api"),
        "drop graphql endpoint",
        ["api requests should now use REST /api/v1 endpoint"],
        [#("Refs", "#123")],
        True,
      ),
    )),
  )
}

pub fn parse_one_with_incomplete_git_output_test() {
  invalid_commit_one
  |> commit.parse_one
  |> should.equal(Error(commit.InvalidCommit(invalid_commit_one)))
}

pub fn parse_one_with_invalid_conventional_attributes_test() {
  invalid_commit_two
  |> commit.parse_one
  |> should.equal(
    Error(commit.InvalidConventionalAttributes(invalid_commit_two)),
  )
}

pub fn parse_list_test() {
  [valid_commit_one, valid_commit_two, invalid_commit_one]
  |> commit.parse_list
  |> should.equal([
    Ok(Commit(
      hash: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      author: Author(name: "johndoe", email: "john@doe.com"),
      date: "Fri Aug 16 01:24:47 2024 +0200",
      conventional_attributes: ca.ConventionalAttributes(
        ca.Chore,
        Some("api"),
        "drop graphql endpoint",
        ["api requests should now use REST /api/v1 endpoint"],
        [#("Refs", "#123")],
        True,
      ),
    )),
    Ok(Commit(
      hash: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      author: Author(name: "janedoe", email: "jane@doe.com"),
      date: "Fri Aug 16 01:24:47 2024 +0200",
      conventional_attributes: ca.ConventionalAttributes(
        ca.Feat,
        None,
        "update homepage styles",
        [],
        [],
        False,
      ),
    )),
    Error(commit.InvalidCommit(invalid_commit_one)),
  ])
}
