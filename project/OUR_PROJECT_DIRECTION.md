# Application direction

This repository is the foundation for an independent digital painting application.

## Established decisions

- First mobile platform: Android.
- Interface architecture: one adaptive interface for phone, tablet, and desktop.
- Painting technology: derived from the upstream Krita codebase.
- Brush strategy: hybrid; retain established Krita brush engines and add a more versatile customization layer.
- User experience reference: the accessibility and workflow patterns of ibisPaint, independently implemented.
- Product differentiator: advanced, modular brush customization without burdening beginner workflows.

## Development constraints

- Preserve upstream copyright and license notices.
- Keep application-specific modifications identifiable and maintainable.
- Preserve Krita document and resource compatibility wherever practical.
- Validate the mobile canvas integration before extensive interface redevelopment.
- This document records product intent; it does not claim that the planned features have been implemented.
