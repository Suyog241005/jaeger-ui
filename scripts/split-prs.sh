#!/usr/bin/env bash
# Splits feat/settings-priority-stack into 4 focused PRs.
# Run from the repository root while on feat/settings-priority-stack.
# Usage: bash scripts/split-prs.sh

set -euo pipefail

BIG_BRANCH="feat/settings-priority-stack"
BASE="upstream/main"

echo "==> Verifying we are on ${BIG_BRANCH}"
CURRENT=$(git branch --show-current)
if [ "$CURRENT" != "$BIG_BRANCH" ]; then
  echo "ERROR: must be on ${BIG_BRANCH}, currently on ${CURRENT}"
  exit 1
fi

# ── helper ─────────────────────────────────────────────────────────────
create_branch() {
  local branch=$1
  shift
  echo ""
  echo "======================================================"
  echo "PR branch: ${branch}"
  echo "======================================================"

  # Delete the branch if it already exists locally
  git branch -D "${branch}" 2>/dev/null || true

  git checkout -b "${branch}" "${BASE}"
  git checkout "${BIG_BRANCH}" -- "$@"
  git add .
  git commit -s -m "$(cat /tmp/commit_msg_$$)"
  git push origin "${branch}" --force
  git checkout "${BIG_BRANCH}"
  rm -f /tmp/commit_msg_$$
}

# ── PR 1: URL utilities ─────────────────────────────────────────────────
cat > /tmp/commit_msg_$$ << 'EOF'
feat(trace): Add URL utilities for layout settings

Adds pure URL helper functions for the layout settings priority stack
(ADR-0010). No React dependency; no UI changes.

- parseSettingsFromUrl(search): reads ?timeline= and ?sidebar= params
  into typed nullable values
- stringifySettings(settings): serialises typed settings back to params
- rebaseSettings(search): strips all layout params, preserving others
- stripSettingParam(search, key): strips only the acted-on param so a
  timeline toggle does not silently drop an active sidebar override
- getUrl / getTracePageLink: extended with optional settings argument
EOF

create_branch feat/settings-url-utilities \
  packages/jaeger-ui/src/components/TracePage/url/index.ts \
  packages/jaeger-ui/src/components/TracePage/url/index.test.js

# ── PR 2: persist flag on Zustand setters ───────────────────────────────
cat > /tmp/commit_msg_$$ << 'EOF'
feat(trace): Add persist flag to layout store setters

Introduces an optional persist?: boolean (default true) on both
Zustand layout setters. When persist=false the store's in-memory
state is updated but localStorage is not written.

This is the mechanism that lets URL-driven and session-toggle updates
take effect without corrupting the user's saved defaults (ADR-0010).
EOF

create_branch feat/settings-persist-flag \
  packages/jaeger-ui/src/components/TracePage/TraceTimelineViewer/store.layout.ts \
  packages/jaeger-ui/src/components/TracePage/TraceTimelineViewer/store.ts

# ── PR 3: TraceViewSettings UI redesign ────────────────────────────────
cat > /tmp/commit_msg_$$ << 'EOF'
feat(trace): Redesign TraceViewSettings as Popover panel

Replaces the Dropdown menu with a structured Popover + Switch panel
(ADR-0010, PR 3). Self-contained UX improvement; no priority stack
logic is included.

- Dropdown -> Popover with Switch controls per setting
- data-testid="trace-view-settings" preserved on the trigger Button
- settingSources / saveSettingAsDefault props accepted (used in PR 5)
- Keyboard shortcuts button opens existing modal
EOF

create_branch feat/settings-ui-redesign \
  packages/jaeger-ui/src/components/TracePage/TracePageHeader/TraceViewSettings.tsx \
  packages/jaeger-ui/src/components/TracePage/TracePageHeader/TraceViewSettings.css \
  packages/jaeger-ui/src/components/TracePage/TracePageHeader/TraceViewSettings.test.jsx \
  packages/jaeger-ui/src/components/TracePage/TracePageHeader/TracePageHeader.tsx

# ── PR 4: useLayoutSettings hook + TracePage wiring ─────────────────────
# This PR needs the url utilities (PR 1) and persist flag (PR 2) to work.
# We base it on upstream/main but include those files as well so it
# compiles standalone; reviewers should merge PR 1 and PR 2 first.
echo ""
echo "======================================================"
echo "PR branch: feat/settings-hook  (stacks on PR 1 + PR 2)"
echo "======================================================"

git branch -D feat/settings-hook 2>/dev/null || true
git checkout -b feat/settings-hook feat/settings-url-utilities

# Bring in persist-flag changes on top
git checkout feat/settings-persist-flag -- \
  packages/jaeger-ui/src/components/TracePage/TraceTimelineViewer/store.layout.ts \
  packages/jaeger-ui/src/components/TracePage/TraceTimelineViewer/store.ts
git add .
git commit -s -m "chore: include persist-flag changes (from feat/settings-persist-flag)"

# Now add the hook + wiring
git checkout "${BIG_BRANCH}" -- \
  packages/jaeger-ui/src/components/TracePage/useLayoutSettings.ts \
  packages/jaeger-ui/src/components/TracePage/useLayoutSettings.test.ts \
  packages/jaeger-ui/src/components/TracePage/index.tsx \
  packages/jaeger-ui/src/components/TracePage/index.test.jsx

git add .
git commit -s -m "feat(trace): Add useLayoutSettings hook and wire TracePage

Implements the cascading URL > heuristic > localStorage priority stack
described in ADR-0010.

- useLayoutSettings(locationSearch): resolves ResolvedSetting<T> for
  each setting; keeps Zustand store in sync via useLayoutEffect
- Revert guard: when a URL param disappears, store reverts to ls default
  only if the user has not manually changed it in the current session
- TracePage: uses resolved values for rendering; toggle handlers call
  stripSettingParam so only the acted-on URL param is stripped

Depends on: feat/settings-url-utilities, feat/settings-persist-flag"

git push origin feat/settings-hook --force
git checkout "${BIG_BRANCH}"

echo ""
echo "======================================================"
echo "All branches pushed:"
echo "  feat/settings-url-utilities  (PR 1)"
echo "  feat/settings-persist-flag   (PR 2)"
echo "  feat/settings-ui-redesign    (PR 3)"
echo "  feat/settings-hook           (PR 4, stacks on PR 1+2)"
echo ""
echo "PR 5 (source badges) is already part of feat/settings-ui-redesign"
echo "since TraceViewSettings already accepts settingSources prop."
echo "A separate PR 5 branch can be cut after PR 3 is merged."
echo "======================================================"
