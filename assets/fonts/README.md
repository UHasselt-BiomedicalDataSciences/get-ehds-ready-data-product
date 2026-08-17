# Web fonts

Self-hosted so the site makes **no third-party requests**.

The `@font-face` declarations live at the top of
[`../css/01-fonts.css`](../css/01-fonts.css) and are referenced by the
`--font` and `--mono` custom properties.

| Family | Weights | Subsets |
| --- | --- | --- |
| Inter | 400, 500, 600 | latin, latin-ext |
| JetBrains Mono | 400, 500 | latin, latin-ext |

`latin` + `latin-ext` covers British English plus European names and
diacritics; the Cyrillic, Greek and Vietnamese subsets are deliberately not
shipped. Each file keeps the `unicode-range` Google published for it, so a
browser only downloads the subset a page actually needs.

## Licence

Both families are released under the **SIL Open Font Licence 1.1**, which
permits redistribution and self-hosting:

- Inter — © 2016 The Inter Project Authors, <https://github.com/rsms/inter>
- JetBrains Mono — © 2020 The JetBrains Mono Project Authors,
  <https://github.com/JetBrains/JetBrainsMono>

## Updating

Fetch the current CSS with a modern browser User-Agent (Google serves woff2
only to browsers that support it), then pull the `latin` and `latin-ext`
`@font-face` blocks and download each `src:` URL into this folder:

```bash
curl -A "Mozilla/5.0 … Chrome/125.0 Safari/537.36" \
  "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap"
```

Then update the `@font-face` block in `../css/01-fonts.css` to match.
