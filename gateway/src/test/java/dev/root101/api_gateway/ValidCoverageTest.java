package dev.root101.api_gateway;

import jakarta.validation.Valid;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.core.type.filter.AnnotationTypeFilter;
import org.springframework.util.ClassUtils;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.lang.reflect.AnnotatedParameterizedType;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Bean validation only runs on a body marked `@Valid` (a list body: its elements): one without it skips every rule, silently.
 */
class ValidCoverageTest {

    @Test
    void everyRequestBodyIsValidated() throws ClassNotFoundException {
        var scanner = new ClassPathScanningCandidateComponentProvider(false);
        scanner.addIncludeFilter(new AnnotationTypeFilter(RestController.class));
        List<String> bodies = new ArrayList<>();
        List<String> missing = new ArrayList<>();
        for (var bean : scanner.findCandidateComponents("dev.root101.api_gateway")) {
            Class<?> controller = ClassUtils.forName(bean.getBeanClassName(), null);
            for (Method method : controller.getDeclaredMethods()) {
                for (Parameter parameter : method.getParameters()) {
                    if (parameter.isAnnotationPresent(RequestBody.class)) {
                        String name = controller.getSimpleName() + "." + method.getName();
                        bodies.add(name);
                        //a list body: on its elements (`List<@Valid X>`)
                        boolean valid = parameter.isAnnotationPresent(Valid.class)
                                || parameter.getAnnotatedType() instanceof AnnotatedParameterizedType list
                                && list.getAnnotatedActualTypeArguments()[0].isAnnotationPresent(Valid.class);
                        if (!valid) missing.add(name);
                    }
                }
            }
        }
        //the scan found the controllers (login + the 5 route writes)
        assertThat(bodies).hasSize(6);
        assertThat(missing).isEmpty();
    }
}
