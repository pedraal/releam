import gleam/option.{type Option, None, Some}
import releam/commit.{type Commit}
import releam/conventional_attributes.{Build, Docs, Feat, Fix, Perf, Refactor}

pub type BumpType {
  Major
  Minor
  Patch
}

pub type Bump {
  Bump(major: Bool, minor: Bool, patch: Bool)
}

pub fn define_bump_type(commits: List(Commit)) {
  case define_bump_type_loop(commits, Bump(False, False, False)) {
    Bump(True, _, _) -> Some(Major)
    Bump(_, True, _) -> Some(Minor)
    Bump(_, _, True) -> Some(Patch)
    _ -> None
  }
}

fn define_bump_type_loop(commits: List(Commit), bump: Bump) {
  case commits {
    [current, ..rest] ->
      define_bump_type_loop(
        rest,
        update_bump(bump, commit_to_bump_type(current)),
      )
    [] -> bump
  }
}

pub fn commit_to_bump_type(current: Commit) {
  case
    current.conventional_attributes.commit_type,
    current.conventional_attributes.breaking
  {
    _, True -> Some(Major)
    ct, _ -> {
      case ct {
        Feat -> Some(Minor)
        Perf | Fix | Refactor | Docs | Build -> Some(Patch)
        _ -> None
      }
    }
  }
}

pub fn update_bump(bump: Bump, update: Option(BumpType)) {
  case update {
    Some(Major) -> Bump(..bump, major: True)
    Some(Minor) -> Bump(..bump, minor: True)
    Some(Patch) -> Bump(..bump, patch: True)
    None -> bump
  }
}
