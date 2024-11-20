# Api-Gateway

This project is structured in several versions, each version with its own configuration and specific features.
Each version has a tag and in that tag the readme explains these particularities.

In general the tag/features relationship is:

| Version | Description                                                                                                                                  |
|---------|----------------------------------------------------------------------------------------------------------------------------------------------|
| 2.x     | Simple gateway, routes are configured via env variable, to change a route the env variable needs to change and the project redeployed.       |
| 3.x     | Simple gateway, BUT, routes are configured via management endpoint, this allow to change routes without redeploying the service.             |
| 4.x     | Gateway with a Postgresql DB, this way we can storage the config in order to reload it if the service need to be redeployed.                 |
| 5.x     | We will add a log filter that storage all requests made to the gateway into DB in order to review all traffic that goes through the service. |
| 6.x     | We will add a monitoring capability to see the availability of the services (the same of the routes of the gateway or any other).            |

NOTE #1: All this version and explanation are some kind of roadmap of what we pretend to ship in next's iterations.

NOTE #2: All features will have its rest api for communication & configuration, BUT, we pretend to develop a UI client
to make the job easier.

NOTE #3: Try to always use the latest version available for each tag. (Eg: The 2.x tag has versions 2.2.0, 2.1.0, 2.0.0;
try to use the latest tag, in this case 2.2.0)

## This is the docs for version 2.x:

---
**title:** Api-Gateway </br>
**description:** A basic ready-to-deploy api gateway </br>
**tags:** </br>

- api-gateway
- spring boot
- java

---

### Env Variables to configure the service:

| Env Variable     | Description                                          | Expected           | Example                  |
|------------------|------------------------------------------------------|--------------------|--------------------------|
| PORT             | The port in which the service will be running        | number             | 8080                     |
| PROFILE          | The profile type of the service                      | text               | DEV                      |
| APPLICATION_NAME | The aplication name                                  | text               | Test App Api-Gateway     |
| ROUTE_CONFIG     | The configuration of the routing for the api gateway | text (json format) | See ROUTE_CONFIG details |

#### ROUTE_CONFIG details

This is probably the most important field in env variables.

This fields need to be a Json representation of the object 'List<RouteConfigModel>'

**Expected:** String, Json format of 'List<RouteConfigModel>'

**Example:**

``` json
    [
      {
         "id":"test-service-of-gateway",
         "path":"/test/**",
         "uri":"https://url-of-test-service.com",
         "replaceFrom":"/test/",
         "replaceTo":"/"
      },
      {
         "id":"push-notification",
         "path":"/notification/**",
         "uri":"https://push-notification.com",
         "replaceFrom":"/notification/",
         "replaceTo":"/"
      }
   ]
```

When this service is configured and deployed, this are a couple of examples of redirection:

| Request to                                                  | Is redirected to                                     |
|-------------------------------------------------------------|------------------------------------------------------|
| https://api-gateway.com/notification/send-push-notification | https://push-notification.com/send-push-notification |
| https://api-gateway.com/notification/{user-id}/send-push    | https://push-notification.com/{user-id}/send-push    |
| https://api-gateway.com/test/some-test-endpoint             | https://url-of-test-service.com/some-test-endpoint   |
| https://api-gateway.com/test/{user-id}/hi-world             | https://url-of-test-service.com/{user-id}/hi-world   |

This it's all for now,

this is after all, a project designed for deploy in railway as a template... so:

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/IR4lVv?referralCode=6_5_ta)
