# Phase 16.1-fix2 — Dashboard Icons provider + local cache

- Dashboard Icons remains the primary icon provider.
- Built-in definitions now carry explicit `ICON_PROVIDER` and `ICON_ID` metadata.
- Verified corrections: Perplexity -> `perplexity`, Trello -> `atlassian-trello`, MEGA -> `mega-nz`, Replit -> DashboardIcons external/LobeHub `replit-color`.
- `manager.sh` prepares a local store-icon cache before catalog generation.
- Resolver order: configured Dashboard Icons SVG -> Dashboard Icons PNG -> website favicon PNG -> bundled generic SVG.
- Runtime manager prefers the local `iconStore`, so successful icons do not depend on the CDN while browsing.
- Cache version bumped to `store-icons-v5`.
