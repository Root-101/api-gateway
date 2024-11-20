package dev.root101.api_gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class App {

    public static void main(String[] args) {
        System.setProperty("PROFILE", "DEV");
        System.setProperty("PORT", "8080");
        System.setProperty("APPLICATION_NAME", "Test Api-Gateway");
        System.setProperty("ROUTE_CONFIG", """
                                           [
                                   {
                                     "id": "auth-dev",
                                     "path": "/auth/**",
                                     "uri": "https://back-authentication-dev.up.railway.app",
                                     "replaceFrom": "/auth/",
                                     "replaceTo": "/"
                                   },
                                   {
                                     "id": "stories-dev",
                                     "path": "/stories/**",
                                     "uri": "https://stories-gateway-2.up.railway.app",
                                     "replaceFrom": "/stories/",
                                     "replaceTo": "/"
                                   },
                                   {
                                     "id": "notifications-dev",
                                     "path": "/notifications/**",
                                     "uri": "https://push-notification-dev.up.railway.app",
                                     "replaceFrom": "/notifications/",
                                     "replaceTo": "/"
                                   },
                                   {
                                     "id": "ads-dev",
                                     "path": "/ads/**",
                                     "uri": "https://ads-control-dev.up.railway.app",
                                     "replaceFrom": "/ads/",
                                     "replaceTo": "/"
                                   },
                                   {
                                     "id": "intl-dev",
                                     "path": "/intl/**",
                                     "uri": "https://intl-dev.up.railway.app",
                                     "replaceFrom": "/intl/",
                                     "replaceTo": "/"
                                   },
                                   {
                                     "id": "onboarding-dev",
                                     "path": "/onboarding/**",
                                     "uri": "https://onboarding-dev.up.railway.app",
                                     "replaceFrom": "/onboarding/",
                                     "replaceTo": "/"
                                   },
                                   {
                                     "id": "users-dev",
                                     "path": "/users/**",
                                     "uri": "https://users-dev.up.railway.app",
                                     "replaceFrom": "/users/",
                                     "replaceTo": "/"
                                   }
                                 ]
                """);

        SpringApplication.run(App.class, args);
    }

}
