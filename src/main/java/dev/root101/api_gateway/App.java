package dev.root101.api_gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class App {

    public static void main(String[] args) {
        System.setProperty("PROFILE", "DEV");
        System.setProperty("PORT", "8080");
        System.setProperty("APPLICATION_NAME", "Test Api-Gateway");
        /*System.setProperty("ROUTE_CONFIG", """
                                           [
                                              {
                                                 "id":"poc-spring-back",
                                                 "path":"/poc/**",
                                                 "uri":"https://api.zyrcled.com",
                                                 "replaceFrom":"/poc/",
                                                 "replaceTo":"/"
                                              },
                                              {
                                                 "id":"zyrcled-notification-dev",
                                                 "path":"/notification/**",
                                                 "uri":"https://push-notification-dev.up.railway.app",
                                                 "replaceFrom":"/notification/",
                                                 "replaceTo":"/"
                                              }
                                           ]
                                           """);*/

        SpringApplication.run(App.class, args);
    }

}
