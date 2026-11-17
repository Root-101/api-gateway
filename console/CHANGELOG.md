* 6.x:
    * 6.1.0:
        * **Add-ons** :jigsaw: : Each route forwards its requests; everything else is an add-on, added, turned
          on or off, edited and removed on its own (needs the gateway `6.1.0`). This version has one: maintenance,
          per route and for the whole gateway. Its panel (the same one in the map and in Routes) shows the redirect,
          the add-ons with an in-place editor and a slide to turn them on or off, and "Add to this route" with the
          ones missing. The 503 message is optional (empty, the gateway's own, marked "default"), and the panel
          shows how long it has been on or the last window. While the gateway is in maintenance it wins: every
          route shows `PAUSED` and its slide is locked. API: `addons` in each route, `GET /addons`, and `PUT`,
          `DELETE`, `POST .../enable` and `.../disable` under `/routes/{id}/addons/maintenance` and
          `/addons/maintenance`.
        * **Health check** :heartpulse: : A second add-on, routes only: the gateway calls a path of the route's
          service every 10 s to 1 h and the console shows the last result. `LIVE` (a 2xx) or `DOWN` next to the
          name (maintenance wins), a `Health · every 30 s` badge on the card, a chip on the map node, and a red,
          still branch in the map while it is down (it still gets its requests). Its block in the panel shows the
          endpoint, the interval and the last check ("12 s ago · 200 in 18 ms"), with "Run now", edit in place
          (endpoint, one of 10 s / 30 s / 1 min / 5 min / 15 min / 1 h, on or off) and remove. Added as
          `/health` every 30 s, on. The routes are reread every 10 s while one has it on (the gateway doesn't
          push). "Add to this route" lists the types the route's `addons` has as keys. API: `PUT`, `DELETE` and
          `POST .../run` under `/routes/{id}/addons/health-check`.
        * **Gateway map** :world_map: : New first entry of the rail: the gateway's URL, the gateway
          and a branch per route with its path, dashed and moving while it forwards, dotted orange while it answers
          `503`. Drag, wheel zoom, `Fit`, an "Add route" card when there are none, and the panel of a route or of the
          gateway on a click. `Open in Routes` filters Routes by that route. It is the start screen: opening the
          console and logging in land on the map instead of Routes. The 404 page offers "Go to map" instead of "Go to
          Routes". The grid behind it pans and zooms with the map.
          Over the canvas the cursor is the drag hand (closed while dragging); nodes and buttons keep the click hand.
        * **Route form** :pencil2: : The preview is no longer a card inside the form: the strip under the title takes
          the card color, as in the canvas.
        * **Routes** :twisted_rightwards_arrows: : Each card has the `MAINT` / `PAUSED` tag, a badge per add-on and
          `+ Add-ons`. Backups keep the `addons` of each route as the gateway sends them (unknown ones too, without
          `default_message` and `state`), and restore sends them back.
        * **Maintenance** :construction: : The banner stays on every screen while the gateway is in maintenance:
          `Edit` opens the map with the gateway's panel, `Turn off` calls `disable`. The first 6.1.0 version (rail
          entry, dialog and wrench on the card, never released) was replaced by the add-ons.
        * **Canvas match** :art: : After comparing every screen with the canvas: "+ Add-ons" on the route cards has a
          dashed border; Routes keeps 3 columns with the rail expanded (380 px cards, 12 px gaps); the route form shows
          each step's title and hint on one line; the maintenance slide is drawn as in the canvas (44 px track, 38 px
          knob with a shadow and a double-chevron, an orange fill behind it, the label fading while dragged; the label
          keeps clear of the knob only on its side, so it isn't cut in the panel); text buttons (Clear all, Go to the
          login page) are bold; dialogs no longer focus a button or the close button when they open (the route form
          still focuses Name).
        * **Maintenance time** :stopwatch: : "On for", "Last window", the gateway node and the banner's countdown use
          larger units ("2h 30 min", "1d 3h") and update every 10 s on their own.
        * **Route panel** :jigsaw: : `Open in Routes` / `Edit route` has the external-link icon of the canvas. Each
          "Add to this route" card has a dashed 1.5 px border, as in the canvas. The
          maintenance slide keeps the handle where it was dropped while it saves (it jumped back to the old side and
          then to the new one), slides to its side when not dragged, and shows the click hand. Removing an add-on asks
          with the canvas buttons: outlined Cancel (no longer focused, so no lilac ring) and filled red Remove. The edit
          buttons (Cancel, Save) are 34 px too, as in the canvas.
        * **Toasts** :speech_balloon: : They show at the bottom center instead of the bottom right, where they
          covered the side panel of the map.
        * **Fix** :bug: : The version under the rail, the login and the splash was empty with `flutter run`: its
          `version.json` comes as javascript there, so it was not read as a map. It is now read as text and decoded.
        * **Fix** :bug: : No toast showed after an action with the loading layer (delete, backup, restore, save a
          route): the `loader_overlay` package painted above the app. The loading layer is now drawn under the
          toast, and the dependency was removed.
        * **Docs** :books: : `docs/console.md` has the Gateway map and Add-ons sections, and the map as the start
          screen; `docs/design` screens 21–24 are the map, and every screen shows the rail and cards as built. The
          canvas has no Experimental page any more (the map and the route panel are with the other screens, the
          superseded maintenance boards are gone), its sample URLs are generic (`example.com`), and the export was
          regenerated from it (`export.py` takes screen 24 from Routes and draws the map with 3 routes).
    * 6.0.0:
        * **DATE** :date: : 2026-11-12.
        * **Redesign** :art: : New visual identity and rebuilt screens: login, side menu with notch, route cards,
          route form with live preview, logs table and filter dialog. New tokens, line icons and DM Mono font.
        * **Routes** :twisted_rightwards_arrows: : Restore has two steps and now replaces every route atomically
          (`PUT /routes`, needs the gateway `6.0.0`). Duplicate opens a pre-filled form named `<name>-copy`.
          The form validates a unique name, a path starting with `/` and an http(s) URL on save.
        * **Logs** :memo: : Numbered pagination (10, 25 or 50 rows) replaces the infinite scroll. Search is automatic
          with a 400 ms debounce. Status filter by family (`2xx`...) or exact code, and a date range calendar.
          Filters are shown as chips in the search box, aligned to its right edge. Fixed the export failing with a
          date filter.
        * **Auth** :lock: : An expired session asks for the password in a dialog over the current screen instead of
          logging out.
        * **States** :traffic_light: : Added first-load skeletons, toasts, a 404 page inside the app and an offline
          banner that retries every 10 s. Errors and warnings are now printed in the browser console of release
          builds (the logger was silent there).
        * **Splash** :art: : The splash of the design is now in `index.html`, so it shows while the app downloads
          instead of a blank page, and it is removed on the first frame. Fixed a refresh (F5) or deep link with a
          remembered session always opening the routes: the splash's navigator reset the url to `/` before the
          router read it.
        * **Docker** :whale: : New `GET /health` in nginx (`{"status":"up"}`), used by the healthcheck in
          `docker-compose.yml`. Before, every path answered `200` with `index.html`.
        * **Dependencies** :package: : Removed `syncfusion_flutter_datagrid` and `top_snackbar_flutter`.
        * **Version** :bookmark: : The console now shares the version of the API Gateway, so both projects are
          released with the same number. It jumps from `1.1.1` to `6.0.0` for that reason.
        * **Deploy** :warning: : Deploy together with the gateway `6.0.0`: with an older gateway a `401`
          arrives as a connection error and does not log out.
        * **Versions** :arrow_up: : Upgrade Flutter to `3.47.9` and all dependencies to their latest versions.
        * **Routes** :twisted_rightwards_arrows: : Fixes: routes without rewrite-path broke the list, editing or
          duplicating wiped the description, the `Redirected to` preview did not match the gateway. Delete asks
          for confirmation and restore validates the file before creating anything.
        * **Routes** :twisted_rightwards_arrows: : Added description field, search, copy URL buttons and edit by
          URL (`/routes/:id/edit`).
        * **Logs** :memo: : Fixes: filter by local day, pagination and retry of failed pages, duplicated logs
          after logout. The export is paginated. Added refresh button, total of results and loading indicator.
        * **Logs** :memo: : A date filter with the dates reversed now covers both days completely.
        * **Auth** :lock: : A `401`/`403` on any screen logs out and a network error no longer does. Added route
          guard, optional inactivity logout (`SESSION_TIMEOUT_MINUTES`), `Remember me` warning and gateway
          status on login. The password is no longer printed in the logs.
        * **Auth** :lock: : Login now uses the gateway token (`Authorization: Bearer`). `Remember me` stores the
          token instead of the password, and a password stored by an older version is removed on start.
        * **Auth** :lock: : A Dio interceptor adds the `Authorization` header, so clients, repositories and cubits
          no longer receive the credential. No change in behaviour.
        * **Routes** :twisted_rightwards_arrows: : `GET /routes/{id}` is parsed with the same shape as the list.
        * **Routes** :twisted_rightwards_arrows: : New `Advanced` section in the route form to set `order`,
          `methods`, `hosts`, `headers` and `filters`. Editing, duplicating, backup and restore keep them.
        * **Routes** :twisted_rightwards_arrows: : `order`, `methods`, `hosts`, `headers` and `filters` are removed,
          following the gateway: the `Advanced` section of the form and the fields in requests, responses and
          backups. A backup that still has them restores without them.
        * **Errors** :hammer_and_wrench: : API errors are parsed safely whatever their format and clear error screen
          when `env.js` is invalid.
        * **i18n** :globe_with_meridians: : Texts migrated to `slang` and all the error messages translated.
        * **i18n** :globe_with_meridians: : Dates (calendar month, log timestamps) and numbers follow the selected
          language; they were always in English.
        * **Docker** :whale: : Reproducible build, `nginx` 1.28 with security headers and no stale files after a deploy.
          `env.js` is generated on container start, so one image serves every environment.
        * **Config** :wrench: : `ADMIN_PATH` is optional and defaults to `_admin`, the same default as the gateway.
          Before, a missing value stopped the console with a configuration error.
        * **API** :electric_plug: : Adapted to the gateway `6.0.0` admin API. Errors are RFC 9457 problem details:
          the field errors of a `422` come from `violations` (`fieldName`, `message`), and the message of any other
          error from `detail`. Login reads `access_token`. Logs use `GET /http-logs` with query parameters and read
          `items`.
        * **Logs** :memo: : The export freezes the end date when it starts, so logs that arrive meanwhile don't
          repeat rows, and it stops at 100 000 logs (the newest), telling you to narrow the filters.
        * **Logs** :memo: : When more than 100 000 logs match, the gateway caps the count (`total_capped`) and
          the console shows `100,000+`. Pages only reach the capped count.
        * **General** :hammer_and_wrench: : Removed unused code (`RouteModel.fromJson`) and the unused `build_runner`
          dependency.
        * **Auth** :lock: : The session expired dialog shows and hides the password, like the login, and says the
          credentials come from `ADMIN_USERNAME` and `ADMIN_PASSWORD`.
        * **Routes** :twisted_rightwards_arrows: : The route form, in three steps (General, Forwarding, Path rewrite) with a compact stepper in the footer. A preview like the card in Routes stays on top and fills in while typing, with a pencil per value that opens its field. Duplicate shows the original route as a chip next to the title, with its warning in a popup. Each Next is checked by the gateway (`POST /routes/validate`): the form no longer keeps its own copy of the rules. The dialog takes the whole height.
        * **Design** :art: : Matched with the canvas: the login brand keeps its side margin (8 % of the window, not
          of its column) and the columns split like the design; the route filter of the logs lists `Admin` and
          `No-Route` before the routes. Restore rejects a file whose names repeat.
        * **Routes** :twisted_rightwards_arrows: : Route names are case-sensitive, like the API: restore, the form's
          taken-name check and the name of a duplicate compare them exactly (`whoami` and `WHOAMI` are two routes).
          They used to ignore case, so a backup with both could not be restored.
        * **Routes** :twisted_rightwards_arrows: : Route form fixes: `Required field` shows on steps 1 and 2, the
          first field with an error gets the focus and scrolls into view with its message, and a route that fails
          to load shows its id once.
        * **Language** :globe_with_meridians: : Every request sends `Accept-Language` with the language of the console, so the gateway answers its validation errors in that language (needs the gateway `6.0.0`).
        * **Logs** :memo: : The details of a log without a route show `No-Route` in the selected language, like the
          table, instead of `NO-ROUTE`.
        * **Docs** :books: : README screenshots now come from `docs/design/screens` and link to `docs/console.md`.
          The README is titled `API Gateway Console`, and says that `GATEWAY_SERVICE_URL` may omit the scheme and
          that nginx answers `GET /health`.
        * **General** :hammer_and_wrench: : Added CI job (analyze and build), updated README, console version in
          the side menu and several memory and UI fixes. The unit tests were removed.
        * **General** :hammer_and_wrench: : Dart package renamed to `console`.
        * **i18n** :globe_with_meridians: : The language change no longer uses `reassembleApplication()`, a
          hot-reload API: the screens behind the selector read their texts with `context.intl`.
        * **General** :hammer_and_wrench: : `get` is only used for dependency injection.
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