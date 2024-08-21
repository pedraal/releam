import gleam/bool
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import releam/commit.{type Commit}
import releam/conventional_attributes.{type CommitType} as ca
import releam/package_config.{type PackageConfig, Github}
import simplifile

pub type ChangelogConfig {
  ChangelogConfig(previous_tag: String, new_tag: String)
}

pub type Section {
  Section(header: CommitType, body: List(Commit))
}

pub type Changelog {
  Changelog(
    title: String,
    compare_link: Result(String, Nil),
    sections: List(Section),
  )
}

pub const changelog_file_path = "./CHANGELOG.md"

const insert_area = "<!-- RELEAM TAG: DON'T DELETE -->\n\n"

pub fn new(
  package_config: PackageConfig,
  config: ChangelogConfig,
  commits: List(Commit),
) {
  let compare_link = generate_compare_link(package_config, config, commits)
  let sections =
    commits
    |> commit.group_by_commit_type
    |> list.map(fn(group) { Section(header: group.0, body: group.1) })

  Changelog(
    title: config.new_tag,
    compare_link: compare_link,
    sections: sections,
  )
}

pub fn render(changelog: Changelog, with_title: Bool) {
  bool.guard(with_title, render_title(changelog.title), fn() { "" })
  <> render_compare_link(changelog.compare_link)
  <> {
    list.map(changelog.sections, fn(section) {
      render_commit_type_header(section.header)
      <> "\n\n"
      <> string.join(list.map(section.body, render_commit(_)), "\n")
    })
    |> string.join("\n\n")
  }
}

pub fn write_to_changelog_file(changelog: Changelog) {
  let assert Ok(_) = case simplifile.is_file(changelog_file_path) {
    Error(_) | Ok(False) -> init_changelog_file()
    _ -> Ok(Nil)
  }

  let assert Ok(content) = simplifile.read(changelog_file_path)

  let new_content =
    string.replace(
      content,
      insert_area,
      insert_area <> render(changelog, True) <> "\n\n",
    )

  case string.contains(content, changelog.title) {
    True -> panic as "new tag already written to changelog file"
    False -> {
      let assert Ok(_) = simplifile.write(changelog_file_path, new_content)
    }
  }
}

pub fn init_changelog_file() {
  let assert Ok(_) = simplifile.create_file(changelog_file_path)
  let assert Ok(_) =
    simplifile.append(changelog_file_path, "# Changelog\n\n" <> insert_area)
}

fn generate_compare_link(
  package_config: PackageConfig,
  config: ChangelogConfig,
  commits: List(Commit),
) {
  case package_config.repository {
    Ok(repo) ->
      case repo.provider {
        Github -> {
          case config.previous_tag {
            "" -> {
              list.last(commits)
              |> result.map(fn(commit) {
                commit.short_hash <> "..." <> config.new_tag
              })
            }
            tag -> Ok(tag <> "..." <> config.new_tag)
          }
          |> result.map(fn(refs) {
            "https://github.com/"
            <> repo.org
            <> "/"
            <> repo.name
            <> "/compare/"
            <> refs
          })
        }
        _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

fn render_title(title: String) {
  "## " <> title <> "\n\n"
}

fn render_compare_link(link: Result(String, Nil)) {
  case link {
    Ok(l) -> "[compare changes](" <> l <> ")\n\n"
    Error(_) -> ""
  }
}

fn render_commit_type_header(commit_type: CommitType) {
  "### "
  <> case commit_type {
    ca.Feat -> "🚀 Enhancements"
    ca.Perf -> "🔥 Performance"
    ca.Fix -> "🩹 Fixes"
    ca.Refactor -> "💫 Refactors"
    ca.Docs -> "📔 Documentation"
    ca.Build -> "📦 Build"
    ca.Chore -> "🧹 Chore"
    ca.Test -> "✅ Tests"
    ca.Style -> "🎨 Styles"
    ca.Ci -> "🤖 CI"
    ca.Custom(_) -> "👀 Others"
  }
}

pub fn render_commit(commit: Commit) {
  let scope = case commit.conventional_attributes.scope {
    Some(scope) -> "**" <> scope <> "**: "
    None -> ""
  }

  "- " <> scope <> string.capitalise(commit.conventional_attributes.description)
}
