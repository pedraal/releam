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
      short_hash: "aaaaaaa",
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
    Commit(
      hash: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      short_hash: "aaaaaaa",
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
    ),
    Commit(
      hash: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      short_hash: "bbbbbbb",
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
    ),
  ])
}

pub fn group_by_commit_type_test() {
  let gen_commit = fn(ct: ca.CommitType) {
    Commit(
      hash: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      short_hash: "aaaaaaa",
      author: Author(name: "johndoe", email: "john@doe.com"),
      date: "Fri Aug 16 01:24:47 2024 +0200",
      conventional_attributes: ca.ConventionalAttributes(
        ct,
        None,
        "lorem ipsum",
        [],
        [],
        False,
      ),
    )
  }

  let feat_commit_one = gen_commit(ca.Feat)
  let feat_commit_two = gen_commit(ca.Feat)
  let fix_commit_one = gen_commit(ca.Fix)
  let fix_commit_two = gen_commit(ca.Fix)
  let fix_commit_three = gen_commit(ca.Fix)
  let perf_commit_one = gen_commit(ca.Perf)

  [
    feat_commit_one,
    feat_commit_two,
    fix_commit_one,
    fix_commit_two,
    fix_commit_three,
    perf_commit_one,
  ]
  |> commit.group_by_commit_type
  |> should.equal([
    #(ca.Feat, [feat_commit_one, feat_commit_two]),
    #(ca.Perf, [perf_commit_one]),
    #(ca.Fix, [fix_commit_one, fix_commit_two, fix_commit_three]),
  ])
}
