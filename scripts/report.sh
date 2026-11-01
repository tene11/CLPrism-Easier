#!/usr/bin/env bash
# Reports the result of check-prism-update.sh and the Windows build on GitHub.
#   report.sh branch  commit the updated patches to branch prism-<TAG> and push it
#   report.sh pr      open (or update) the pull request for branch prism-<TAG>
#   report.sh issue   open an issue explaining what failed (REASON = apply-failed | build-failed)
# Needs TAG and, for "pr" and "issue", CURRENT in the environment.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
work="${WORK_DIR:-$root/.work}"
mode="$1"
branch="prism-$TAG"
run_url="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}"
cd "$root"

case "$mode" in
branch)
    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git switch --quiet --force-create "$branch"
    git add PRISM_VERSION patches
    git commit --quiet -m "Follow Prism Launcher $TAG"
    git push --quiet --force --set-upstream origin "$branch"
    ;;
pr)
    body="$(cat <<BODY
Prism Launcher **$TAG** が出たので、パッチを当て直しました（これまでは $CURRENT）。

- パッチはそのまま当たりました
- Windows 版のビルドとテストも通りました（[実行結果]($run_url)。ビルドした zip はそこから先に試せます）

マージすると、新しいバージョンがビルドされて Releases に置かれます。
BODY
)"
    if [ -n "$(gh pr list --head "$branch" --state open --json number --jq '.[].number')" ]; then
        gh pr edit "$branch" --body "$body"
    else
        gh pr create --base main --head "$branch" --title "Prism Launcher $TAG に追従" --body "$body"
    fi
    ;;
issue)
    mkdir -p "$work"
    if [ "$REASON" = "apply-failed" ]; then
        title="Prism Launcher $TAG: パッチが当たりません"
        what="パッチを当てる途中で失敗しました。Prism 側のコードが変わったので、パッチの修正が必要です。"
    else
        title="Prism Launcher $TAG: パッチは当たるが Windows 版のビルドに失敗します"
        what="パッチはそのまま当たりましたが、ビルドかテストが失敗しました。Prism 側の関数などが変わった可能性があります。パッチを当てた状態はブランチ \`$branch\` にあります。"
    fi
    {
        echo "Prism Launcher **$TAG** が出ましたが、自動では追従できませんでした（いまのパッチは $CURRENT 向け）。"
        echo
        echo "$what"
        echo
        if [ -f "$work/am.log" ] && [ "$REASON" = "apply-failed" ]; then
            echo "<details><summary>git am のログ</summary>"
            echo
            echo '```'
            tail -n 80 "$work/am.log"
            echo '```'
            echo
            echo "</details>"
            echo
        fi
        echo "Actions の実行結果（ログはここから見られます）: $run_url"
    } > "$work/issue.md"
    gh issue create --title "$title" --body-file "$work/issue.md"
    ;;
*)
    echo "usage: $0 branch|pr|issue" >&2
    exit 2
    ;;
esac
