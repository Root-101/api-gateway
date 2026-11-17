package dev.root101.api_gateway.features.settings.data;

import dev.root101.api_gateway.features.settings.data.entity.SettingValue;
import io.r2dbc.postgresql.codec.Json;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.data.convert.ReadingConverter;
import org.springframework.data.convert.WritingConverter;
import org.springframework.data.r2dbc.convert.R2dbcCustomConversions;
import org.springframework.data.r2dbc.dialect.PostgresDialect;

import java.util.List;

@Configuration
public class SettingsConfig {

    //replaces boot's empty one: the jsonb of `setting.value`
    @Bean
    public R2dbcCustomConversions r2dbcCustomConversions() {
        return R2dbcCustomConversions.of(PostgresDialect.INSTANCE, List.of(new ToJson(), new FromJson()));
    }

    @WritingConverter
    static class ToJson implements Converter<SettingValue, Json> {
        @Override
        public Json convert(SettingValue source) {
            return Json.of(source.json());
        }
    }

    @ReadingConverter
    static class FromJson implements Converter<Json, SettingValue> {
        @Override
        public SettingValue convert(Json source) {
            return new SettingValue(source.asString());
        }
    }
}
