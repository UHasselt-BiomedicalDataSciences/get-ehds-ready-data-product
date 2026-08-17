# Contributing

## Prerequisites

Only [Quarto](https://quarto.org) is needed — no other tooling. Install it from
<https://quarto.org/docs/get-started/>, then check it:

```bash
quarto --version       # 1.6.41 is the version CI pins
quarto check           # confirms the install is healthy
```

Using VS Code or RStudio? Install the **Quarto extension** for live preview and
editing support (RStudio 2022.07+ bundles Quarto already).

The three commands you need day to day — `quarto preview`, `quarto render` and
`./_scripts/ci.sh` — are in the [README's quick start](README.md#quick-start).

## The checks

`_scripts/ci.sh` is the same script GitHub Actions runs, so a green run locally
means a green run in CI. It checks that every page is registered and present,
that no source file has been left untracked, that no credentials are committed, that the render succeeds, and that the built site loads nothing from a third party.

Run it before every push. It catches the mistakes that are invisible locally but
break the published site — a page you forgot to register, a source file left
untracked, a resource loaded from a third party.

## Project layout

```text
.
├── _quarto.yml                  # site config (minimal HTML + shared includes + stylesheets)
├── index.qmd                    # landing page, authored in Markdown
├── data-product-canvas.qmd      # step 1 — design
├── data-product-design.qmd      # step 2 — build
├── omop-cdm-switchbox.qmd       # step 3 — scale to cross-border research
├── references.bib               # bibliography used for in-text citations
├── ieee.csl                     # citation style (the independent IEEE style)
├── README.md                    # what the project is, and where to read the site
├── CONTRIBUTING.md              # this file
├── CITATION.cff                 # how to cite this repository
├── LICENSE                      # CC BY 4.0 for docs, MIT for code, third-party exceptions
├── .gitignore                   # keeps docs/, _book/ and the manuscript out of git
├── .github/workflows/
│   ├── ci.yml                   #   build, privacy and security checks
│   └── publish.yml              #   renders and deploys to GitHub Pages
├── _scripts/                    # helper scripts (not published)
│   └── ci.sh                    #   the checks; run this before pushing
├── _includes/                   # HTML partials injected on every page (not published)
│   ├── head.html                #   <head> extras — no third-party resources
│   ├── header.html              #   nav bar → top of <body>
│   ├── footer.html              #   footer, copyright and licence → end of <body>
│   └── citation-tooltips.html   #   hover-preview script hook for citations
├── _templates/                  # copy-me starters (not published)
│   ├── subpage-template.qmd     #   the starter you copy for a new page
│   ├── subpage-template.html    #   self-contained preview (open in a browser)
│   └── _quarto.example.yml      #   reference config for a multi-page site
├── assets/                      # static files copied into the site
│   ├── css/01-fonts.css …       #   the stylesheet, in nine ordered parts
│   ├── fonts/                   #   self-hosted Inter + JetBrains Mono, with their OFL terms
│   ├── images/logo.png          #   logo used by the header and footer
│   └── js/citation-tooltips.js  #   hover-preview behaviour for citations
└── docs/                        # render output — git-ignored, built by CI
```

Directories whose names start with `_` are ignored by Quarto: never rendered as
pages, never copied into `docs/`. That is what keeps partials, templates,
scripts and the private book out of the published site.

`_templates/subpage-template.html` is a **self-contained** preview of the
template (CSS, fonts and logo all inlined) — open it directly in a browser.

## How the build works

`_quarto.yml` renders every page as `minimal: true` HTML — so the only styling
is the site's own stylesheets, not Bootstrap — and injects the shared chrome on
every page:

- `include-in-header:   _includes/head.html`   → `<head>` extras
- `include-before-body: _includes/header.html` → the nav bar
- `include-after-body:  _includes/footer.html` → the footer
- `include-after-body:  _includes/citation-tooltips.html` → citation hover-previews
- `css: [assets/css/01-fonts.css, …]`          → the look

Every rendered page therefore gets the same header, footer and styling without
it ever being copied into a page. The site language is British English
(`lang: en-GB`).

### The stylesheet

`assets/css/` holds nine numbered parts, from `01-fonts.css` to
`09-prose-components.css`. **The order in `_quarto.yml` is the cascade** —
`08-responsive.css` refines everything above it, so add new files deliberately
rather than alphabetically. Available components: `.hero`, `.split`, `.card` /
`.card-grid`, `.layer-cake`, `.canvas-grid`, `.flow`, `.pillars`, `.sb-flow`,
`.insight`, `.gr-callout`, `.quote-band`, plus the paragraph styles `.p-lead`,
`.p-muted`, `.p-note`.

## Adding a page

1. `cp _templates/subpage-template.qmd about.qmd`
2. Write Markdown. For a styled component, use a fenced div, e.g. `::: {.gr-callout}`.
3. Register the page in `_quarto.yml` under `render:` (a `- about.qmd` line).
   This project lists pages explicitly, so a new page is not built until it is
   added here — `./_scripts/ci.sh` fails if you forget.
4. Add it to the nav in `_includes/header.html`
   (e.g. `<li><a href="about.html">About</a></li>`).
5. `quarto render` → `docs/about.html`, with the shared header and footer.

To build every root-level `*.qmd` automatically instead, replace the `render:`
list with the `- "*.qmd"` glob. To let Quarto manage navigation with its native
navbar instead of the custom header, see
[`_templates/_quarto.example.yml`](_templates/_quarto.example.yml).

## Authoring notes

- **Write in British English.** `-ise` not `-ize` (organisation, harmonisation,
  standardisation), `-our` not `-or` (behaviour, colour), *centre*, *artefact*,
  *ageing*, *licence* as a noun and *license* as a verb, and `-ae-`/`-oe-` in
  medical terms (paediatric, anaemia, oesophagus). Dates read *26 March 2029*.
  Leave identifiers alone — CSS properties (`color`, `text-align: center`), the
  HTML `rel="license"` keyword, URLs, citation keys and the `LICENSE` filename
  are code, not prose, and the official name of a licence keeps its own spelling
  (*MIT License*, *Creative Commons Attribution 4.0 International License*).
  The language is declared in three places, all of which must agree: `lang:
  en-GB` in `_quarto.yml` and in each page's front matter.
- Wrap page content in `::: {.gr-section}` → `::: {.section-inner}` to match the
  site's padding and max width.
- The section wrapper class is **`.gr-section`** (not `.section`) and the custom
  callout is **`.gr-callout`** (not `.callout`) — `section` and `callout` are
  reserved words that Quarto/Pandoc rewrites. Use these, not Quarto's built-in
  callouts, which need the default theme this site strips out.
- **Citations:** add a BibTeX entry to `references.bib` and cite it as `[@key]`.
  Citations render as IEEE-style bracketed numbers with hover pop-ups. The
  bibliography itself is hidden by the stylesheet (`#refs`), so keep the
  `::: {#refs}` placeholder div on any page that uses citations — citeproc
  renders the entries into it and the pop-ups read them from there. Only cited
  entries are rendered.
  `ieee.csl` must stay the *independent* IEEE style; a dependent style (one that
  only points at a parent) has no `<citation>` element and citeproc refuses it.

## Privacy rules

The published site makes **no third-party requests**, and `_scripts/ci.sh`
enforces it. Fonts are self-hosted in `assets/fonts/`, the only script is
`assets/js/citation-tooltips.js`, and there is no analytics or tag manager.
Loading fonts from a CDN would send every visitor's IP address to a third party
before any consent, so keep external links out of `_includes/head.html`.

## Committing changes

Run `./_scripts/ci.sh`, then commit and push:

```bash
git switch -c short-topic-branch    # keep main deployable
git add -A                          # docs/ and _book/ are ignored, so they stay out
git commit -m "Short summary in the imperative, e.g. Add OMOP mapping section"
git push -u origin HEAD
```

Open a pull request; CI runs on it. Merging to `main` publishes the site.

## Publishing

Pushing to `main` runs [`ci.yml`](.github/workflows/ci.yml) and then
[`publish.yml`](.github/workflows/publish.yml), which renders the site and
deploys it to GitHub Pages (Settings → Pages → Source = "GitHub Actions"). There
is no `gh-pages` branch: the render is uploaded as a Pages artefact. The rendered
site is a build artefact and is not committed.
