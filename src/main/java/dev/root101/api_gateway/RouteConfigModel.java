package dev.root101.api_gateway;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RouteConfigModel {

    private String id;
    private String path;
    private String uri;
    private String replaceFrom;
    private String replaceTo;
}
