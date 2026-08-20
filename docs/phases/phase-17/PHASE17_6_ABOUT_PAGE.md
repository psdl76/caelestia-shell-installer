# Phase 17.6 — About Page

Status: **ACCEPTED / FROZEN**

## Goal

Add a first-class About destination to the Manager using the same information
architecture as the Caelestia Nexus settings About page.

## UI contract

- `Über` is a persistent, standalone navigation item at the bottom of the
  sidebar.
- It opens as a normal main page through the established Nexus StackPage
  transition, not as a dialog or overlay.
- Because it is a top-level destination, its page header has no back button.
- A large product card shows the existing WebApps symbol, product name and the
  version read from the packaged `VERSION` file.
- Connected information groups identify the developer (`psdl76`), purpose,
  runtime technology, design reference and stable interface versions.

## Architecture boundary

The page is informational. It neither invokes the CLI nor changes persistent
state. The visual structure follows the official Nexus About page while using
only project-owned QML components and public Qt/Quickshell APIs.
