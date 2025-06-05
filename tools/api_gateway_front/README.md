# Api-Gateway Front

This project is the ui client to handle the admin of the api gateway with ease.

This project will be updated with latest version of api gateway

#### About v1.x:

This version is the first iteration in the integration with api-gateway

### Env Variables to configure the client:

To configure the project we have a couple of environmental variables at our disposal. These are:

| Env Variable        | Description                                                                                 | Expected | Default value (and example) | Added in version |
|---------------------|---------------------------------------------------------------------------------------------|----------|-----------------------------|------------------|
| GATEWAY_SERVICE_URL | The url of the api gateway service                                                          | text     | https://gataway-url.test    | 1.0.0            |
| ADMIN_PATH          | The admin path of the gateway service (should be the same as ADMIN_PATH in gateway-service) | text     | _admin                      | 1.0.0            |

### Flutter

Since I'm a single developer, and the frontend technology I know is flutter, I made this client using, you guess it:
Flutter.

Currently, using version `3.32.1`, latest as today (05-dd/06-mm/2025-yy)

## The end

This it's all for now... so... deploy it and test it yourself:

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/IR4lVv?referralCode=6_5_ta)
