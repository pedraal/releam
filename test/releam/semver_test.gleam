import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import releam/commit.{Author, Commit}
import releam/conventional_attributes.{
  type CommitType, Build, Chore, Ci, ConventionalAttributes, Custom, Docs, Feat,
  Fix, Perf, Refactor, Style, Test,
}
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
    gen_fake_commit(combination.0, True)
    |> semver.commit_to_bump_type
    |> should.equal(Some(Major))

    gen_fake_commit(combination.0, False)
    |> semver.commit_to_bump_type
    |> should.equal(combination.1)
  })
}

pub fn define_bump_type_test() {
  [gen_fake_commit(Feat, False)]
  |> semver.define_bump_type
  |> should.equal(Some(Minor))

  [gen_fake_commit(Feat, True)]
  |> semver.define_bump_type
  |> should.equal(Some(Major))

  [gen_fake_commit(Fix, False), gen_fake_commit(Docs, False)]
  |> semver.define_bump_type
  |> should.equal(Some(Patch))

  [gen_fake_commit(Ci, False), gen_fake_commit(Test, False)]
  |> semver.define_bump_type
  |> should.equal(None)

  [gen_fake_commit(Ci, False), gen_fake_commit(Test, True)]
  |> semver.define_bump_type
  |> should.equal(Some(Major))

  [
    gen_fake_commit(Feat, False),
    gen_fake_commit(Fix, True),
    gen_fake_commit(Chore, False),
  ]
  |> semver.define_bump_type
  |> should.equal(Some(Major))
}

fn gen_fake_commit(ct: CommitType, breaking: Bool) {
  Commit(
    "",
    Author("johndoe", "john@doe.com"),
    "",
    conventional_attributes: ConventionalAttributes(
      ct,
      None,
      "",
      [],
      [],
      breaking,
    ),
  )
}
