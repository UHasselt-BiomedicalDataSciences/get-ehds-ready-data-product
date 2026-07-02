# Get EHDS ready data product

Quarto website for the **GET REHDY** technical work package.
Pages are written in Markdown and rendered to static HTML in `docs/`, ready for GitHub Pages.

## Install Quarto

This site needs only [Quarto](https://quarto.org) — no other tooling. Download and run the installer from <https://quarto.org/docs/get-started/>.

Verify the installation:

```bash
quarto --version       # should print 1.6 or newer
quarto check           # confirms the install is healthy
```

> Using VS Code or RStudio? Install the **Quarto extension** for live preview
> and editing support (RStudio 2022.07+ bundles Quarto already).

## Quick start

Once Quarto is installed, from the repository root:

```bash
quarto preview         # live-reloading local preview
quarto render          # build the whole site into docs/
```

## Project layout

```text
.
├── _quarto.yml                  # site config (minimal HTML + shared includes + stylesheet)
├── index.qmd                    # landing page, authored in Markdown
├── references.bib               # bibliography used for in-text citations
├── _includes/                   # HTML partials injected on every page (not published)
│   ├── head.html                #   web-font links → <head>
│   ├── header.html              #   nav bar (matches header.png) → top of <body>
│   ├── footer.html              #   footer (matches footer.png) → end of <body>
│   └── citation-tooltips.html   #   hover-preview script hook for citations
├── _templates/                  # copy-me starters (not published)
│   ├── subpage-template.qmd     #   the starter you copy for a new page
│   ├── subpage-template.html    #   self-contained preview (open in a browser)
│   └── _quarto.example.yml      #   reference config for a multi-page site
├── assets/                      # static files copied into the site
│   ├── css/get-rehdy.css        #   the GET REHDY stylesheet (all components)
│   ├── images/logo.png          #   logo used by the header and footer
│   ├── js/citation-tooltips.js  #   hover-preview behaviour for citations
│   └── ieee.csl                 #   citation style used for the bibliography
├── docs/                        # render output — publish this folder
└── LICENSE
```

Folders and files whose names start with `_` (`_includes/`, `_templates/`) are
ignored by Quarto: they are never rendered as pages and never copied into
`docs/`. That is the idiomatic way to keep partials and templates out of the
published site.

`_templates/subpage-template.html` is a **self-contained** preview of the
template (CSS, fonts and logo all inlined) — open it directly in a browser to
see what a subpage looks like. It is not part of the published site.

## How it works

`_quarto.yml` renders every page as `minimal: true` HTML — so the only styling
is `assets/css/get-rehdy.css`, not Bootstrap — and injects the shared chrome on
every page:

- `include-before-body: _includes/header.html` → the nav bar
- `include-after-body:  _includes/footer.html` → the footer
- `include-after-body:  _includes/citation-tooltips.html` → citation hover-previews
- `include-in-header:   _includes/head.html`   → the web fonts
- `css: assets/css/get-rehdy.css`              → the look

So `quarto render` turns `index.qmd` (Markdown) into a fully styled
`docs/index.html`, and **every page that is rendered gets the same header,
footer and styling** — the shared chrome is never copied into a page. The site
language is set to **British English** (`lang: en-GB`).

## Adding a page

1. `cp _templates/subpage-template.qmd about.qmd`
2. Write Markdown. For a styled component, use a fenced div, e.g. `::: {.gr-callout}`.
3. Register the page in `_quarto.yml` by adding it to the `render:` list
   (a `- about.qmd` line) — this project lists pages explicitly, so a new page
   is not built until it is added here.
4. Add the page to the nav in `_includes/header.html`
   (e.g. `<li><a href="about.html">About</a></li>`).
5. `quarto render` → `docs/about.html`, complete with the shared header and footer.

`_quarto.yml` currently lists only `index.qmd` under `render:`, so each new page
must be registered there (step 3). To build every root-level `*.qmd`
automatically instead, replace the list with the `- "*.qmd"` glob. If you would
rather have Quarto manage the navigation with its native navbar instead of the
custom header, see
[`_templates/_quarto.example.yml`](_templates/_quarto.example.yml), which spells
out both approaches.

## Authoring notes

- Wrap page content in `::: {.gr-section}` → `::: {.section-inner}` to match the
  site's padding and max width.
- The section wrapper class is **`.gr-section`** (not `.section`) and the custom
  callout is **`.gr-callout`** (not `.callout`) — because `section` and `callout`
  are reserved words that Quarto/Pandoc rewrites. Use these, not Quarto's
  built-in callouts (which need the default theme this site strips out).
- Available components (see `assets/css/get-rehdy.css`): `.hero`, `.split`,
  `.card` / `.card-grid`, `.layer-cake`, `.canvas-grid`, `.flow`, `.pillars`,
  `.sb-flow`, `.insight`, `.gr-callout`, `.quote-band`, plus the paragraph
  styles `.p-lead`, `.p-muted`, `.p-note`.
- **Citations:** add a BibTeX entry to `references.bib` and cite it as
  `[@key]`. Citations render as IEEE-style bracketed numbers with hover
  pop-ups (`assets/js/citation-tooltips.js`). The bibliography itself is
  hidden by the stylesheet (`#refs`), so keep the `::: {#refs}` placeholder
  div on any page that uses citations — citeproc renders the entries into it,
  and the pop-ups read them from there. Only entries that are actually cited
  are rendered.
