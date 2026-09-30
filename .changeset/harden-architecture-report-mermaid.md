---
"mattpocock-skills": patch
---

improve-codebase-architecture: harden the HTML report's Mermaid setup. `securityLevel` moves from `loose` to `strict`, so HTML in a diagram label is escaped rather than rendered; labels are built from identifiers read out of the codebase, and under `loose` a hostile one could inject markup into a report you open locally. The CDN import also pins an exact version (`mermaid@11.17.2`) instead of the floating `@11`, so a future upstream release cannot change what a generated report executes.
