pub const git_log_commit_re = "^commit\\s([0-9a-f]{40})$\\n^Author:\\s(.+)\\s<(.+)>$\\n^Date:\\s+(.+)$\\n\\n((?:\\s{4}.+\\n?)+)(?:\\n?(?:\\s{4}.+\\n?)+)?$"
