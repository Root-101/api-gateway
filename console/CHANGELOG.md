* 6.x:
    * 6.2.0:
        * **Errors** :warning: : Reads the gateway 6.2.0 errors: the `422`'s `errors` (`pointer`, `code`, `detail`) instead
          of `violations`, shown on the same fields as before. Needs gateway 6.2.0.
        * **Versions** :arrow_up: : Flutter `3.47.9` → `3.50.1` (Dart `3.14`) in `.fvmrc`, the `Dockerfile` and the CI.
          Material widgets from the `material_ui` package (`package:flutter/material.dart` is deprecated since 3.47),
          `flutter_localizations` no longer a direct dependency. Every package on its latest version (`go_router`
          `18.1.4`, `flutter_svg` `2.5.0`). No lint warnings left.
        * **Texts** :pencil2: : Spanish slide switches shortened to "Desliza para …" (the handle already shows the
          direction): the longer ones were cut in the route panel ("Desliza a la izquierda para dejar de co…").
    * 6.1.2:
        * **DATE** :date: : 2026-11-19.
        * **Version** :bookmark: : Version adjustment to match the gateway, no changes in the console.
    * 6.1.1:
        * **DATE** :date: : 2026-11-19.
        * **Gateway map** :world_map: : The gateway node shows its add-ons at the bottom, as the route nodes do:
          `Maintenance · on/off` (orange when on) and `Rate limit · on/off` (blue when on) when configured, and `CORS`
          (always on). The node is wider and taller and the routes sit lower to keep the branches' length.
    * 6.1.0:
        * **DATE** :date: : 2026-11-18.
        * **Add-ons** :jigsaw: : Each route forwards its requests; everything else is an add-on, added, turned on or
          off, edited and removed on its own (needs the gateway `6.1.0`), per route and, except the health check, for
          the whole gateway. Its panel (the same one in the map and in Routes) shows the redirect (for the gateway, an
          **Overview** with its URL and how many routes are checked, down, in maintenance, limited or with their own
          CORS), a block per add-on with its data, an in-place editor, a slide across the block to turn it on or off and
          an (i) popup with what it does, and "Add to this route" with the ones missing.
        * **Maintenance** :construction: : An optional 503 message (empty: the gateway's own, marked "default"), and how
          long it has been on or the last window ("2h 30 min", updated every 10 s). While the gateway is in maintenance
          it wins: every route shows `PAUSED` with its slide locked, and a banner on every screen offers `Edit` and
          `Turn off`.
        * **Health check** :heartpulse: : Routes only: the gateway calls a path of the service every 10 s to 1 h. `LIVE`
          or `DOWN` with the last check ("12 s ago · 200 in 18 ms"), "Run now", and a red, still branch in the map while
          it is down. Added as `/health` every 30 s, on; the routes are reread every 10 s while one has it on.
        * **Rate limit** :stopwatch: : A limit of requests per second, minute or hour per client IP, with an optional
          burst; past it, a 429. Added as 60 / minute, burst 10, off, since it changes traffic.
        * **CORS** :globe_with_meridians: : The allowed browser origins (`https://app.com`, `https://*.example.com`,
          `*`) as chips, checked as they are typed, and, routes only, credentials, locked off while an origin lets in
          any site. The gateway's always exists (no slide, no remove) and warns when its list leaves out the origin this
          console runs on; a route's is added off with the gateway's origins. While the deprecated
          `CORS_ALLOWED_ORIGINS` is set, a banner says whether it was moved into the gateway's CORS (blue, can be
          closed) or differs and is ignored (yellow, with both lists).
        * **Gateway map** :world_map: : The new start screen, first in the rail: the gateway's URL, the gateway and a
          branch per route with its path, dashed and moving while it forwards, dotted orange in maintenance, red while
          down. Drag, wheel zoom, `Fit`, and the panel of a route or of the gateway on a click, which can expand to a
          big centered panel with the blocks in 3 columns. `Open in Routes` filters Routes by that route.
        * **Routes** :twisted_rightwards_arrows: : Each card has the `MAINT` / `PAUSED` tag, a badge per add-on and `+
          Add-ons`. Backups keep each route's `addons` and restore sends them back.
        * **Design** :art: : Matched with the canvas: route cards, the route form's preview strip and step titles, the
          maintenance slide, bold text buttons, and dialogs that don't focus a button when they open. Toasts at the
          bottom center, so they don't cover the map's panel.
        * **Fix** :bug: : The version was empty with `flutter run`; no toast showed after an action with the loading
          layer (`loader_overlay` removed); Logs with many rows scrolled the whole screen (now only the rows scroll); an
          older reload of the routes could overwrite a newer one.
        * **Code** :broom: : The map, Routes, the route form, Logs and the shell split into widgets of their own, the
          add-on blocks share their header and remove confirmation, and `AppDateRangeDialog` and `DashedBorder` are in
          the design system.
        * **Docs** :books: : `docs/console.md` has the map and the add-ons, `docs/design` has screens 21–24 and every
          screen as built, and the console README lists the map and the add-ons.
    * 6.0.0:
        * **DATE** :date: : 2026-11-12.
        * **Version** :bookmark: : The console shares the version of the API Gateway, so it jumps from `1.1.1` to
          `6.0.0`. Deploy it together with the gateway `6.0.0`.
        * **Redesign** :art: : New visual identity and rebuilt screens: login, side menu with notch, route cards, route
          form with live preview, logs table and filter dialog. New tokens, line icons and DM Mono font. The splash is
          in `index.html`, so it shows while the app downloads.
        * **API** :electric_plug: : Adapted to the gateway `6.0.0` admin API: the login's Bearer token (`access_token`),
          Problem Details errors (`violations` for a `422`, `detail` otherwise, parsed safely whatever their format),
          `GET /http-logs`, and `Accept-Language` on every request so the gateway answers in the console's language.
        * **Auth** :lock: : `Remember me` stores the token, not the password (one stored by an older version is
          removed). A `401`/`403` logs out, a network error doesn't, and an expired session asks for the password in a
          dialog over the current screen. Route guard, optional inactivity logout (`SESSION_TIMEOUT_MINUTES`) and the
          gateway's status on the login. The password is no longer printed in the logs.
        * **Routes** :twisted_rightwards_arrows: : The route form in three steps (General, Forwarding, Path rewrite)
          with a live preview, each step checked by the gateway (`POST /routes/validate`). Description, search, copy URL
          buttons, edit by URL (`/routes/:id/edit`), duplicate as `<name>-copy`, and delete with confirmation. Restore
          in two steps, checked first and atomic (`PUT /routes`); names are case-sensitive, like the API. `order`,
          `methods`, `hosts`, `headers` and `filters` removed, following the gateway (a backup that has them restores
          without them). Fixes: routes without rewrite-path broke the list, editing wiped the description, the
          `Redirected to` preview didn't match the gateway.
        * **Logs** :memo: : Numbered pagination (10, 25 or 50 rows) instead of the infinite scroll, automatic search,
          status filter by family or exact code, a date range calendar, filters as chips, refresh and the total of
          results (`100,000+` when the gateway caps it). The export is paginated, freezes its end date and stops at 100
          000 logs. Fixes: filter by local day, reversed dates, retry of failed pages, duplicated logs after logout.
        * **States** :traffic_light: : First-load skeletons, toasts, a 404 page inside the app and an offline banner
          that retries every 10 s. Errors are printed in the browser console of release builds.
        * **i18n** :globe_with_meridians: : Texts with `slang`, every error message translated, and dates and numbers in
          the selected language.
        * **Docker** :whale: : Reproducible build, `nginx` 1.28 with security headers, `GET /health` for the
          healthcheck, and `env.js` generated on container start, so one image serves every environment. `ADMIN_PATH` is
          optional (default `_admin`).
        * **Versions** :arrow_up: : Flutter `3.47.9` and every dependency to its latest version;
          `syncfusion_flutter_datagrid`, `top_snackbar_flutter` and `build_runner` removed.
        * **General** :hammer_and_wrench: : CI job (analyze and build), the console version in the side menu, the Dart
          package renamed to `console`, and `get` only for dependency injection. The unit tests were removed.
        * **Docs** :books: : The README is titled `API Gateway Console`, with screenshots from `docs/design/screens` and
          a link to `docs/console.md`.
* 1.x:
    * 1.1.1:
        * **DATE** :date: : 2026-05-17.
        * **General** :hammer_and_wrench: : Fix validation in routes form.
        * **General** :hammer_and_wrench: : Upgrade Flutter sdk to latest 3.41.9.
    * 1.1.0:
        * **DATE** :date: : 2025-09-10.
        * **General** :hammer_and_wrench: : Match version with general api gateway version. We
          basically skip all version to math this 5.x version with the one in the core project.
        * **General** :hammer_and_wrench: : Added the Http Logs system.
        * **Auth** :lock: : Added the `Remember me` option in login.
    * 1.0.0:
        * **DATE** :date: : 2024-11-20.
        * **General** :hammer_and_wrench: : Initial version of this **web base UI-client**.