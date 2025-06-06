* 4.x:
    * 4.2.0:
        * **DATE** :date: : 2025-06-05.
        * **General** :hammer_and_wrench: : Created a UI client to handle admin api with ease. (details
          in `tools/api_gateway_front/CHANGELOG.MD`)
        * **General** :hammer_and_wrench: : Add needed endpoint to client (like `auth/login` to validate correct user)
    * 4.1.0:
        * **DATE** :date: : 2025-05-05.
        * **Docker** :whale: : Migrated to dockerfile to use/build-run the project as a native image using graalvm,
          using image: `gradle:jdk-21-and-22-graal-jammy`.
        * **General** :hammer_and_wrench: : Migrated all project to handle specific of native image
    * 4.0.1:
        * **DATE** :date: : 2025-04-04.
        * **Docker** :whale: : Change sdk image in Dockerfile, from `openjdk:21-jdk-oracle`
          to `eclipse-temurin:21-jre-alpine` (lighter image, like 15-20% less ram usage and like 50% size reduction)
    * 4.0.0:
        * **DATE** :date: : 2024-12-25.
        * **General** :hammer_and_wrench: : Initial version 4.0.0 (first of tag 4.x).

* 3.x:
    * 3.0.0:
        * **DATE** :date: : 2024-12-02.
        * **General** :hammer_and_wrench: : Initial version 3.0.0 (first of tag 3.x).

* 2.x:
    * 2.2.0:
        * **DATE** :date: : 2024-11-20.
        * **General** :hammer_and_wrench: : Initial version/deploy of lib as a (little) more formal project.