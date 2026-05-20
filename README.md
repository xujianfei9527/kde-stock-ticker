# Stock Ticker Plasma Widget

This is a minimal Plasma 6 widget that shows one A-share quote directly in the panel.

Default symbol:
- `513500`

Data source:
- Eastmoney JSON endpoint, queried directly from QML

Files:
- `metadata.json`
- `contents/ui/main.qml`

Install to:

```bash
~/.local/share/plasma/plasmoids/com.evan.stockticker/
```

Then add `Stock Ticker` to the Plasma panel.

If Plasma does not pick up the widget immediately, restart Plasma Shell:

```bash
kquitapp6 plasmashell && kstart plasmashell
```
