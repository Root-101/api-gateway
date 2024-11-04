# Api-Gateway

---
**title:** Api-Gateway </br>
**description:** A basic ready-to-deploy api gateway </br>
**tags:** </br>
  - api-gateway
  - spring boot
  - java
---

### Env Variables to configura the service:

| Env Variable     | Description                                          | Expected           | Example                  |
| ---------------- | ---------------------------------------------------- | ------------------ | ------------------------ |
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


This is after all a project designed for deplay in railway as a template... so:

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/IR4lVv?referralCode=6_5_ta)
