#!/usr/bin/env bash
# GET REHDY — build, privacy and security checks.
#
# Run this before pushing:
#
#     ./_scripts/ci.sh
#
# The same script runs in GitHub Actions (.github/workflows/ci.yml), so a green
# run locally means a green run there.
set -uo pipefail

cd "$(dirname "$0")/.."

FAILED=0
pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAILED=1; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# Files to search when checking sources. Excludes build output and the private
# book, and only considers text we actually author.
src_files() {
  git ls-files -z 2>/dev/null | tr '\0' '\n' | grep -vE '^docs/' || true
}

# ─────────────────────────────────────────────────────────────────────────────
head_ "1. Toolchain"
# ─────────────────────────────────────────────────────────────────────────────
if command -v quarto >/dev/null 2>&1; then
  pass "quarto $(quarto --version)"
else
  fail "quarto not found on PATH — install from https://quarto.org/docs/get-started/"
fi

# ─────────────────────────────────────────────────────────────────────────────
head_ "2. Project consistency"
# ─────────────────────────────────────────────────────────────────────────────
# Every page listed in _quarto.yml must exist, or the render dies halfway.
missing=""
while read -r page; do
  [ -z "$page" ] && continue
  [ -f "$page" ] || missing="$missing $page"
done < <(sed -n '/^  render:/,/^  [a-z]/p' _quarto.yml | sed -n 's/^    - //p')
if [ -n "$missing" ]; then
  fail "pages listed in _quarto.yml but missing from disk:$missing"
else
  pass "every page in the _quarto.yml render list exists"
fi

# A page on disk that nobody registered is a page that never gets built.
# Files starting with "_" are skipped: Quarto never renders them as pages, they
# are include partials pulled in with {{< include >}}, and listing one under
# render: would build it as a stray standalone page.
unlisted=""
for f in *.qmd; do
  [ -e "$f" ] || continue
  case "$f" in _*) continue ;; esac
  grep -qE "^    - $f\$" _quarto.yml || unlisted="$unlisted $f"
done
if [ -n "$unlisted" ]; then
  fail "pages on disk not listed under render: in _quarto.yml:$unlisted"
else
  pass "every .qmd on disk is registered for rendering"
fi

# Every stylesheet part must be wired up, in order.
for part in assets/css/*.css; do
  grep -q "$part" _quarto.yml || fail "$part is not listed under css: in _quarto.yml"
done
pass "stylesheet parts are wired into _quarto.yml"

# The bug that once left the live site half-published: source files that exist
# locally but were never committed. CI always sees a clean checkout, so this
# only ever fires locally — which is exactly where it needs to.
untracked=$(git ls-files --others --exclude-standard 2>/dev/null || true)
if [ -n "$untracked" ]; then
  fail "source files exist but are not in git — the published site will be missing them:"
  printf '      %s\n' $untracked
else
  pass "no untracked source files"
fi

# ─────────────────────────────────────────────────────────────────────────────
head_ "3. The book stays private"
# ─────────────────────────────────────────────────────────────────────────────
if git ls-files | grep -qE '^_book/'; then
  fail "files under _book/ are tracked by git — the private manuscript must never be committed"
else
  pass "nothing under _book/ is tracked"
fi
if git ls-files | grep -qiE '\.(pdf|docx)$'; then
  fail "a PDF or Word file is tracked — check it is not the private manuscript:"
  git ls-files | grep -iE '\.(pdf|docx)$' | sed 's/^/      /'
else
  pass "no PDF or Word build products are tracked"
fi
# The trailing slash matters. check-ignore stats the path, so without it git
# treats "_book" as a file and the directory-only rule /_book/ does not match —
# which is every CI checkout, where the ignored directory is simply absent.
if git check-ignore -q _book/ 2>/dev/null; then
  pass "_book/ is git-ignored"
else
  fail "_book/ is NOT git-ignored — restore the rule in .gitignore"
fi

# ─────────────────────────────────────────────────────────────────────────────
head_ "4. Secrets"
# ─────────────────────────────────────────────────────────────────────────────
secret_hits=$(src_files | xargs -I{} grep -HnE \
  'BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|(api[_-]?key|secret|passwd|password|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}' \
  {} 2>/dev/null || true)
if [ -n "$secret_hits" ]; then
  fail "possible credential committed:"
  printf '      %s\n' "$secret_hits"
else
  pass "no credential-shaped strings in tracked files"
fi

# ─────────────────────────────────────────────────────────────────────────────
head_ "5. Render"
# ─────────────────────────────────────────────────────────────────────────────
if command -v quarto >/dev/null 2>&1; then
  if quarto render >/tmp/gr-render.log 2>&1; then
    pass "quarto render succeeded ($(find docs -name '*.html' | wc -l | tr -d ' ') pages)"
  else
    fail "quarto render failed:"
    sed 's/^/      /' /tmp/gr-render.log | tail -30
  fi
else
  warn "skipping render — quarto is not installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
head_ "6. Privacy — the published site must make no third-party requests"
# ─────────────────────────────────────────────────────────────────────────────
# Only resource-loading positions matter. Ordinary prose links to external sites
# are expected and are not a privacy problem: the visitor's browser contacts
# those hosts only if they choose to click.
if [ -d docs ]; then
  ext=$(grep -rnoE '<(script|img|iframe|source|embed|video|audio)[^>]+src="https?://[^"]+' docs --include='*.html' 2>/dev/null || true)
  ext="$ext$(grep -rnoE '<link[^>]+href="https?://[^"]+' docs --include='*.html' 2>/dev/null || true)"
  ext="$ext$(grep -rnoE '@import[^;]*https?://[^;]+' docs --include='*.html' --include='*.css' 2>/dev/null || true)"
  ext="$ext$(grep -rnoE 'url\(["'"'"']?https?://[^)]+' docs --include='*.html' --include='*.css' 2>/dev/null || true)"
  ext=$(printf '%s' "$ext" | grep -v '^$' || true)
  if [ -n "$ext" ]; then
    fail "the rendered site loads resources from another host:"
    printf '      %s\n' "$ext"
  else
    pass "no externally loaded scripts, styles, images, fonts or iframes"
  fi

  trackers=$(grep -rnoiE 'googletagmanager|google-analytics|gtag\(|googlesyndication|doubleclick|facebook\.net|hotjar|matomo|plausible\.io|segment\.(io|com)|mixpanel' docs --include='*.html' --include='*.js' 2>/dev/null || true)
  if [ -n "$trackers" ]; then
    fail "analytics or tracking code found in the rendered site:"
    printf '      %s\n' "$trackers"
  else
    pass "no analytics or tracking code"
  fi

  gfonts=$(grep -rnoE '(href|url\()["'"'"']?https?://fonts\.(googleapis|gstatic)\.com' docs --include='*.html' --include='*.css' 2>/dev/null || true)
  if [ -n "$gfonts" ]; then
    fail "web fonts are being loaded from Google — they must stay self-hosted in assets/fonts/:"
    printf '      %s\n' "$gfonts"
  else
    pass "web fonts are self-hosted"
  fi

  insecure=$(grep -rnoE '(src|href)="http://[^"]+' docs --include='*.html' 2>/dev/null | grep -viE 'http://www\.w3\.org' || true)
  if [ -n "$insecure" ]; then
    fail "plain-http URL (mixed content, and stripped of transport privacy):"
    printf '      %s\n' "$insecure"
  else
    pass "no plain-http URLs"
  fi
else
  warn "docs/ not present — skipping the checks that inspect rendered output"
fi

# ─────────────────────────────────────────────────────────────────────────────
head_ "7. Security"
# ─────────────────────────────────────────────────────────────────────────────
if [ -d docs ]; then
  # A target="_blank" link without rel="noopener" hands the opened page a
  # reference to this one via window.opener. Modern browsers imply noopener,
  # but stating it keeps older ones safe and documents the intent.
  blank=$(grep -rnoE '<a[^>]+target="_blank"[^>]*>' docs --include='*.html' 2>/dev/null | grep -v 'noopener' || true)
  if [ -n "$blank" ]; then
    fail 'target="_blank" link without rel="noopener":'
    printf '      %s\n' "$blank"
  else
    pass 'every target="_blank" link carries rel="noopener"'
  fi

  if grep -rq 'name="referrer"' docs --include='*.html' 2>/dev/null; then
    pass "referrer policy is declared"
  else
    fail "no referrer policy meta tag — expected it from _includes/head.html"
  fi
fi

# The one first-party script the site ships. innerHTML with page-derived content
# is how a citation pop-up would become an injection point.
if [ -f assets/js/citation-tooltips.js ]; then
  if grep -qE '\binnerHTML\b|document\.write|eval\(|new Function\(' assets/js/citation-tooltips.js; then
    warn "assets/js/citation-tooltips.js uses innerHTML/eval — confirm the content it inserts is page-derived and trusted"
  else
    pass "no innerHTML, document.write or eval in the site script"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
if [ "$FAILED" -eq 0 ]; then
  printf '\n\033[32mAll checks passed.\033[0m\n'
else
  printf '\n\033[31mChecks failed.\033[0m Fix the ✗ items above before pushing.\n'
fi
exit "$FAILED"
