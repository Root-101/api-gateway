## Api-Gateway

### Env Variables to configura the service:

#### PROFILE
The profile type of the service.

Expected: any
Example: DEV

#### PORT
The port in wich the service will be running

Expected: number
Example: 8080

#### APPLICATION_NAME
The aplication name

Expected: String
Example: Test App Api-Gateway

#### ROUTE_CONFIG
The configuration of the routing for the api gateway
This is probably the most important field.

This fields is suppost to be a Json representation of the object 'List<RouteConfigModel>'

Expected: String, Json format of 'List<RouteConfigModel>'
Example: 
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