package dev.root101.api_gateway.config;

import jakarta.validation.MessageInterpolator;
import org.springframework.context.MessageSource;
import org.springframework.web.server.ServerWebExchange;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

/**
 * The languages of the admin API's texts (`messages.properties`, `messages_es.properties`), picked by the request's
 * `Accept-Language`; English when it is missing or names another language. Errors carry a key of those files, and
 * the error handler writes its text in the language of the request.
 */
public final class I18n {

    public static final List<Locale> LOCALES = List.of(Locale.ENGLISH, Locale.of("es"));

    //between the text of each language in a bean validation message
    private static final String SEPARATOR = "\u001F";

    private I18n() {
    }

    /**
     * The language of the request, one of {@link #LOCALES}
     */
    public static Locale locale(ServerWebExchange exchange) {
        Locale requested = exchange.getLocaleContext().getLocale();
        if (requested != null) {
            for (Locale locale : LOCALES) {
                if (locale.getLanguage().equals(requested.getLanguage())) return locale;
            }
        }
        return Locale.ENGLISH;
    }

    /**
     * Bean validation runs where the request isn't at hand (controllers, use cases): each message is interpolated
     * in every language, and {@link #text} keeps the one of the request.
     */
    public static MessageInterpolator everyLanguage(MessageInterpolator delegate) {
        return new MessageInterpolator() {
            @Override
            public String interpolate(String template, Context context) {
                return LOCALES.stream()
                        .map(locale -> delegate.interpolate(template, context, locale))
                        .collect(Collectors.joining(SEPARATOR));
            }

            @Override
            public String interpolate(String template, Context context, Locale locale) {
                return delegate.interpolate(template, context, locale);
            }
        };
    }

    /**
     * The text of a message in the given language: a key of the messages files with its args, or a bean validation
     * message in every language. Anything else (a text that isn't a key) is returned as is.
     */
    public static String text(MessageSource messages, String message, Object[] args, Locale locale) {
        if (message == null) return null;
        if (message.contains(SEPARATOR)) {
            String[] texts = message.split(SEPARATOR, -1);
            int i = LOCALES.indexOf(locale);
            return texts[i >= 0 && i < texts.length ? i : 0];
        }
        return messages.getMessage(message, args, message, locale);
    }
}
