package dev.root101.api_gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
@SpringBootApplication
public class App {

    public static void main(String[] args) {
        System.out.println("--------------------------------------------------");
        System.out.println(System.getProperty("DB_HOST"));
        System.out.println("--------------------------------------------------");

        SpringApplication.run(App.class, args);
    }

}