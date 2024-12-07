package dev.root101.api_gateway;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.TestInstance;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.PostgreSQLContainer;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public abstract class BaseTest {
    private static final String DB_NAME = "test";
    private static final String DB_USER = "postgres";
    private static final String DB_PASSWORD = "admin123**";

    public static final String ADMIN_PATH = "_auth";
    public static final String ADMIN_USERNAME = "admin";
    public static final String ADMIN_PASSWORD = "admin123**";

    private static final PostgreSQLContainer<?> postgresContainer = new PostgreSQLContainer<>("postgres:15.6")
            .withDatabaseName(DB_NAME)
            .withUsername(DB_USER)
            .withPassword(DB_PASSWORD);

    @BeforeAll
    public static void startContainer() {
        postgresContainer.start();
        System.setProperty("DB_HOST", postgresContainer.getHost());
        System.setProperty("DB_PORT", postgresContainer.getMappedPort(5432).toString());
        System.setProperty("DB_NAME", DB_NAME);
        System.setProperty("DB_USERNAME", DB_USER);
        System.setProperty("DB_PASSWORD", DB_PASSWORD);
        System.setProperty("ADMIN_USERNAME", ADMIN_USERNAME);
        System.setProperty("ADMIN_PASSWORD", ADMIN_PASSWORD);
    }

    @TestConfiguration
    static class TestConfig {
        @Bean
        public PostgreSQLContainer<?> postgresContainer() {
            return postgresContainer;
        }
    }
}
