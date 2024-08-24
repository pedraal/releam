import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import releam/commit.{Author, Commit}
import releam/conventional_attributes.{
  type CommitType, Build, Chore, Ci, Custom, Docs, Feat, Fix, Perf, Refactor,
  Style, Test,
} as ca
import releam/semver.{Bump, Major, Minor, Patch}

pub fn main() {
  gleeunit.main()
}

pub fn update_bump_test() {
  semver.update_bump(Bump(False, False, False), Some(Major))
  |> should.equal(Bump(True, False, False))

  semver.update_bump(Bump(False, False, False), Some(Minor))
  |> should.equal(Bump(False, True, False))

  semver.update_bump(Bump(False, False, False), Some(Patch))
  |> should.equal(Bump(False, False, True))

  semver.update_bump(Bump(False, False, False), None)
  |> should.equal(Bump(False, False, False))
}

pub fn commit_to_bump_type_test() {
  [
    #(Feat, Some(Minor)),
    #(Perf, Some(Patch)),
    #(Fix, Some(Patch)),
    #(Refactor, Some(Patch)),
    #(Docs, Some(Patch)),
    #(Build, Some(Patch)),
    #(Style, None),
    #(Test, None),
    #(Ci, None),
    #(Chore, None),
    #(Custom("any"), None),
  ]
  |> list.each(fn(combination) {
    gen_commit(combination.0, True)
    |> semver.define_commit_bump_type
    |> should.equal(Some(Major))

    gen_commit(combination.0, False)
    |> semver.define_commit_bump_type
    |> should.equal(combination.1)
  })
}

pub fn define_bump_type_test() {
  [gen_commit(Feat, False)]
  |> semver.define_bump_type
  |> should.equal(Some(Minor))

  [gen_commit(Feat, True)]
  |> semver.define_bump_type
  |> should.equal(Some(Major))

  [gen_commit(Fix, False), gen_commit(Docs, False)]
  |> semver.define_bump_type
  |> should.equal(Some(Patch))

  [gen_commit(Ci, False), gen_commit(Test, False)]
  |> semver.define_bump_type
  |> should.equal(None)

  [gen_commit(Ci, False), gen_commit(Test, True)]
  |> semver.define_bump_type
  |> should.equal(Some(Major))

  [gen_commit(Feat, False), gen_commit(Fix, True), gen_commit(Chore, False)]
  |> semver.define_bump_type
  |> should.equal(Some(Major))
}

fn gen_commit(ct: CommitType, breaking: Bool) {
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
      breaking,
    ),
  )
}
