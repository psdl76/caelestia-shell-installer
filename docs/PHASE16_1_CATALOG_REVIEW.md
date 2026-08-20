# Phase 16.1 — Core Catalog & Applet Capability Schema v2

Core catalog: **79 apps** across **14 categories**.
Featured: **23** · Applet available: **21** · Supported applets: **4**.

All applets default to disabled. `experimental` means the adapter is conceptually suitable but has not yet been live-accepted for that app.

## Applet schema

| Field | Meaning |
|---|---|
| `APPLET_AVAILABLE` | Applet may be offered |
| `APPLET_DEFAULT_ENABLED` | Default opt-in; always `false` in Phase 16.1 |
| `APPLET_ADAPTER` | `none`, `notifications`, `media`, `calendar`, `mail` |
| `APPLET_SUPPORT` | `none`, `experimental`, `supported` |
| `APPLET_CAPABILITIES` | Generic adapter features |
| `APPLET_MATCH_HOSTS` | Optional host matching hints |

## Catalog

### AI

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| ChatGPT | ★ | — | — | — |
| Claude | ★ | — | — | — |
| Gemini | ★ | — | — | — |
| Perplexity | ★ | — | — | — |
| DeepSeek |  | — | — | — |
| Grok |  | — | — | — |
| Microsoft Copilot |  | — | — | — |

### Messaging

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Discord | ★ | notifications | experimental | notifications, badge, preview |
| Google Messages | ★ | notifications | supported | notifications, badge, preview |
| Telegram | ★ | notifications | experimental | notifications, badge, preview |
| WhatsApp | ★ | notifications | supported | notifications, badge, preview |
| Messenger |  | notifications | experimental | notifications, badge, preview |
| Microsoft Teams |  | notifications | experimental | notifications, badge, preview |
| Slack |  | notifications | experimental | notifications, badge, preview |

### Google

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Gmail | ★ | mail | experimental | unread, latest_mail |
| Google Calendar | ★ | calendar | experimental | next_event, upcoming_events |
| Google Drive | ★ | — | — | — |
| Google Contacts |  | — | — | — |
| Google Docs |  | — | — | — |
| Google Keep |  | — | — | — |
| Google Maps |  | — | — | — |
| Google Meet |  | notifications | experimental | notifications |
| Google Photos |  | — | — | — |
| Google Sheets |  | — | — | — |

### Microsoft

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Microsoft 365 |  | — | — | — |
| OneDrive |  | — | — | — |
| Outlook |  | mail | experimental | unread, latest_mail |

### Proton

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Proton Drive | ★ | — | — | — |
| Proton Mail | ★ | mail | experimental | unread, latest_mail |
| Lumo |  | — | — | — |
| Proton Calendar |  | calendar | experimental | next_event, upcoming_events |
| Proton Docs |  | — | — | — |
| Proton Meet |  | notifications | experimental | notifications |
| Proton Pass |  | — | — | — |
| Proton Sheets |  | — | — | — |

### Productivity

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Asana |  | — | — | — |
| Miro |  | — | — | — |
| Notion |  | — | — | — |
| Todoist |  | — | — | — |
| Trello |  | — | — | — |

### Social

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Facebook | ★ | — | — | — |
| Instagram | ★ | — | — | — |
| LinkedIn |  | — | — | — |
| Reddit |  | — | — | — |
| TikTok |  | — | — | — |
| X |  | — | — | — |

### Video

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Amazon Prime Video | ★ | — | — | — |
| Disney+ | ★ | — | — | — |
| Netflix | ★ | — | — | — |
| YouTube | ★ | media | supported | now_playing, playback_controls, live_preview, video_crop, pin |
| ARD Mediathek |  | — | — | — |
| Joyn |  | — | — | — |
| MagentaTV |  | — | — | — |
| Paramount+ |  | — | — | — |
| Twitch |  | media | experimental | now_playing, playback_controls, live_preview |
| WOW |  | — | — | — |
| ZDF |  | — | — | — |

### Music

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Spotify | ★ | media | experimental | now_playing, playback_controls, artwork |
| YouTube Music | ★ | media | supported | now_playing, playback_controls, artwork |
| Deezer |  | media | experimental | now_playing, playback_controls, artwork |
| SoundCloud |  | media | experimental | now_playing, playback_controls, artwork |
| TIDAL |  | media | experimental | now_playing, playback_controls, artwork |

### Development

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| GitHub |  | — | — | — |
| GitLab |  | — | — | — |
| Replit |  | — | — | — |
| Stack Overflow |  | — | — | — |

### Design

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Canva |  | — | — | — |
| Figma |  | — | — | — |
| Photopea |  | — | — | — |

### Cloud

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Dropbox |  | — | — | — |
| MEGA |  | — | — | — |
| pCloud |  | — | — | — |

### Shopping

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Amazon | ★ | — | — | — |
| Kleinanzeigen | ★ | — | — | — |
| eBay |  | — | — | — |
| Etsy |  | — | — | — |

### Travel

| App | Featured | Applet | Support | Capabilities |
|---|:---:|---|---|---|
| Airbnb |  | — | — | — |
| Booking.com |  | — | — | — |
| Deutsche Bahn |  | — | — | — |
