# Detailed API Docs

A fine grain explanation of every endpoint, with example, models... everything

## Table of Contents

- [1 - Overview](#1)
    - [1.1 - How it work](#1.1)


##### Route request model:

This is the full json of a route request model.

```json
{
  "name": "test-dev",
  "path": "/test-service/**",
  "uri": "http://localhost:8081",
  "description": "A test route",
  "rewrite_path": {
    "replace_from": "/test-service/",
    "replace_to": "/"
  }
}
```

NOTE: The route response model is basically the same with the `id` and `created_at` attribute.

Here we have:

| Field        | Required | Description                                                                                                | Validations                        | Recommendations                                                                                                                                                                                                                                                             |
|--------------|----------|------------------------------------------------------------------------------------------------------------|------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name         | true     | Name with which this route will be identified (human like name). It's an unique identifier for each route. | - Not null<br/>-Not Empty          | Use a unique, easy to identify value                                                                                                                                                                                                                                        |
| path         | true     | Route with which the redirection to a specific service will be identified                                  | - Not null<br/>-Not Empty          | Use in the format /{path}/**, this means that all requests made to https://gateway/{path}/..... will be redirected to this route                                                                                                                                            |
| uri          | true     | Url of the service to which you are going to redirect                                                      | - Not null<br/>-Not Empty<br/>-Url | Use same base url of the service (preferably a private URL without internet access, which can only be accessed through the gateway)                                                                                                                                         |
| description  | false    | Additional description of the route                                                                        |                                    | Use it for some basic descriptive description of the route                                                                                                                                                                                                                  |
| rewrite_path | false    | 'Filter' to rewrite the final path to which the request is made (replace in final url the *from* => *to*)  | - Not null<br/>-Not Empty<br/>     | Use to fix the extra path added by path property. With example, a request made to:  https://gateway/abcd/users/search, by default will be redirected to: http://localhost:8081/abcd/users/search, but with rewrite will be redirected to http://localhost:8081/users/search |


##### Login model:

This is the full json of the login model.

```json
{
  "username": "admin",
  "password": "admin123**"
}
```

Here we have:

| Field    | Required | Description                                          | Validations               | Recommendations                                   |
|----------|----------|------------------------------------------------------|---------------------------|---------------------------------------------------|
| username | true     | Username of the admin user. Default to `admin`.      | - Not null<br/>-Not Empty | It's the one configured in env: `ADMIN_USERNAME`  |
| password | true     | Password of the admin user. Default to `admin123**`. | - Not null<br/>-Not Empty | It's the one configured in env: `ADMIN_PASSWORD`. |

##### Http Log search model:

```json
{
  "page": 0,
  "size": 20,
  "query": "",
  "from_date": "2025-08-01T00:00:00Z",
  "to_date": "2025-08-30T23:59:59Z",
  "response_code": 200,
  "method": "POST",
  "route_id": "00000000-0000-0000-0000-000000000000"
}
```

Here we have:

| Field         | Required | Description                                                              | Validations                            | Recommendations                                                                                                      |
|---------------|----------|--------------------------------------------------------------------------|----------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| page          | true     | Page to search (to allow paginating the logs).                           | - Not null<br/>-Positive or cero (>=0) |                                                                                                                      |
| size          | false    | Size of the page to load.                                                | - Positive (>0)                        | A null value will load all the logs in DB. Used in the export of UI client                                           |
| query         | false    | Used to filter results, matched against: `user_agent`, `path`, `route`.  |                                        |                                                                                                                      |
| from_date     | false    | Used to filter results, loads logs with `requested_date` >= `from_date`. |                                        |                                                                                                                      |
| to_date       | false    | Used to filter results, loads logs with `requested_date` <= `to_date`.   |                                        |                                                                                                                      |
| response_code | false    | Used to filter results, loads logs with this exact `response_code`.      |                                        |                                                                                                                      |
| method        | false    | Used to filter results, loads logs with this exact `http_method`.        |                                        |                                                                                                                      |
| route_id      | false    | Used to filter results by `route`.                                       |                                        | Use `00000000-0000-0000-0000-000000000000` to filter by the admin route, and `NO-ROUTE` to filter logs with no route |

##### Http Log model:

This is the full json of the search and http log model.

```json
{
  "page": 0,
  "size": 20,
  "total_pages": 1,
  "total_elements": 1,
  "page_content": [
    {
      "id": "0d4e3312-c08f-452d-be8d-b351f7e2be4f",
      "source_ip": "0:0:0:0:0:0:0:1",
      "requested_at": "2025-08-25T11:00:00.612396-08:00",
      "user_agent": "PostmanRuntime/7.45.0",
      "http_method": "POST",
      "path": "/_admin/auth/login",
      "response_code": 200,
      "request_duration": 2,
      "route": {
        "route_id": "00000000-0000-0000-0000-000000000000",
        "route_name": "Admin",
        "route_path": "http://localhost:8080/_admin/auth/login"
      }
    }
  ]
}
```

Here we have a wrapper with the page info:

| Field          | Description                                |
|----------------|--------------------------------------------|
| page           | The current page searched                  |
| size           | The size of the searched page              |
| total_pages    | The total amount of pages with this config |
| total_elements | The total amount of logs in DB             |
| page_content   | The real list of http logs model           |

The Http Log Model in the `page_content`:

| Field            | Description                                                                                                                                                            |
|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| id               | Unique UUID that identifies the log entry.                                                                                                                             |
| source_ip        | IP address from which the request was made.                                                                                                                            |
| requested_at     | Exact date and time when the request was made.                                                                                                                         |
| user_agent       | String identifying the client, browser, or tool that made the request.                                                                                                 |
| http_method      | HTTP method used for the request (e.g., GET, POST, PUT, DELETE).                                                                                                       |
| path             | The requested HTTP path or endpoint.                                                                                                                                   |
| response_code    | HTTP status code returned by the server (e.g., 200, 404, 500).                                                                                                         |
| request_duration | Time taken by the server to process the request, expressed in milliseconds.                                                                                            |
| route            | Object containing information about the associated route. It will be **null** if no route was resolved in this request (neither a configured route nor an admin route) |

And the Route in the `route` object:

| Field      | Description                                                                                                                                                    |
|------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| route_id   | Unique UUID of the associated route. This is generated in the create route endpoint. It will be `00000000-0000-0000-0000-000000000000` in case the admin route |
| route_name | Name of the associated route.                                                                                                                                  |
| route_path | Full URL or base path of the associated route.                                                                                                                 |

##### Redirection Examples:

Let's assume we start the server and call the endpoint of multi-add to configure the initial routes, this is the
configuration we use:

```json
[
  {
    "id": "notifications-dev",
    "path": "/notification/**",
    "uri": "https://push-notification.com",
    "rewrite_path": {
      "replace_from": "/notification/",
      "replace_to": "/"
    }
  },
  {
    "id": "test-dev",
    "path": "/test/**",
    "uri": "https://url-of-test-service.com",
    "rewrite_path": {
      "replace_from": "/test/",
      "replace_to": "/"
    }
  },
  {
    "id": "versioning",
    "path": "/ver/**",
    "uri": "https://otherrandomservice.com"
  }
]
```

With this configuration we will note that a:

| Request to                                                  | Is redirected to                                     |
|-------------------------------------------------------------|------------------------------------------------------|
| https://api-gateway.com/notification/send-push-notification | https://push-notification.com/send-push-notification |
| https://api-gateway.com/notification/{user-id}/send-push    | https://push-notification.com/{user-id}/send-push    |
| https://api-gateway.com/test/some-test-endpoint             | https://url-of-test-service.com/some-test-endpoint   |
| https://api-gateway.com/test/{user-id}/hi-world             | https://url-of-test-service.com/{user-id}/hi-world   |
| https://api-gateway.com/ver/magic-endpoint                  | https://otherrandomservice.com/ver/magic-endpoint    |
