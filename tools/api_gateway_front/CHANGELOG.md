* 1.x:
    * 1.2.0 (in progress):
        * **DATE** :date: : not released yet (started 2026-11-02).
        * **Deploy** :warning: : Deploy together with the gateway `5.1.0`: with an older gateway a `401`
          arrives as a connection error and does not log out.
        * **Versions** :arrow_up: : Upgrade Flutter to `3.47.9` and all dependencies to their latest versions.
        * **Routes** :twisted_rightwards_arrows: : Fixes: routes without rewrite-path broke the list, editing or
          duplicating wiped the description, the `Redirected to` preview did not match the gateway. Delete asks
          for confirmation and restore validates the file before creating anything.
        * **Routes** :twisted_rightwards_arrows: : Added description field, search, copy URL buttons and edit by
          URL (`/routes/:id/edit`).
        * **Logs** :memo: : Fixes: filter by local day, pagination and retry of failed pages, duplicated logs
          after logout. The export is paginated. Added refresh button, total of results and loading indicator.
        * **Auth** :lock: : A `401`/`403` on any screen logs out and a network error no longer does. Added route
          guard, optional inactivity logout (`SESSION_TIMEOUT_MINUTES`), `Remember me` warning and gateway
          status on login. The password is no longer printed in the logs.
        * **Errors** :hammer_and_wrench: : API errors are parsed safely whatever their format and clear error screen
          when `env.js` is invalid.
        * **i18n** :globe_with_meridians: : Texts migrated to `slang` and all the error messages translated.
        * **Docker** :whale: : Reproducible build, `nginx` 1.28 with security headers and no stale files after a deploy.
          `env.js` is generated on container start, so one image serves every environment.
        * **General** :hammer_and_wrench: : Added unit tests and CI job, updated README, console version in the
          side menu and several memory and UI fixes.
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