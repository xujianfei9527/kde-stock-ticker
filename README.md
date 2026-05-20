# Stock Ticker Plasma Widget

A small Plasma 6 panel widget for tracking a single A-share quote in real time.
It is designed to stay lightweight: the UI is rendered in QML, and the quote is
fetched by a small Python helper.

## Features

- Shows one stock or ETF code directly in the Plasma panel
- Displays current price, change, change percentage, open, high, low, previous close, volume, and amount
- Uses color cues for up/down/flat movement
- Auto-refreshes every 30 seconds by default
- Supports 6-digit A-share codes and infers the market prefix automatically

## Data Source

- Sina Finance quote endpoint
- The QML UI calls `contents/stock_quote.py` through Plasma's executable data source

## Default Configuration

- Default code: `513500`
- Default refresh interval: `30000` ms

You can change the default stock code in `contents/ui/main.qml`:

```qml
property string stockCode: "513500"
```

## Repository Layout

- `metadata.json` - Plasma plugin metadata
- `contents/ui/main.qml` - widget UI and polling logic
- `contents/stock_quote.py` - quote fetcher and formatter

## Install

Copy the widget folder into your local Plasma plasmoid directory:

```bash
~/.local/share/plasma/plasmoids/com.evan.stockticker/
```

Then add `Stock Ticker` from the Plasma widget chooser.

If Plasma does not pick up the widget immediately, restart Plasma Shell:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Notes

- This widget currently focuses on a single quote only.
- If you publish the project on GitHub, replace the placeholder author and website
  values in `metadata.json` with your own information.
