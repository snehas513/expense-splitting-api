
import requests


class APIError(Exception):
    def __init__(self, message, status_code=None):
        super().__init__(message)
        self.status_code = status_code


class APIClient:
    def __init__(self, base_url, token=None, timeout=20):
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.timeout = timeout

    def _request(self, method, path, payload=None):
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"

        try:
            response = requests.request(
                method,
                f"{self.base_url}{path}",
                json=payload,
                headers=headers,
                timeout=self.timeout,
            )
        except requests.RequestException as exc:
            raise APIError(
                f"Could not reach the Rails API: {exc}"
            ) from exc

        try:
            data = response.json()
        except ValueError:
            data = {"raw_response": response.text}

        if not response.ok:
            errors = (
                data.get("errors")
                or data.get("error")
                or data.get("message")
                or data
            )

            raise APIError(
                f"API returned HTTP {response.status_code}: {errors}",
                status_code=response.status_code,
            )

        if isinstance(data, dict) and data.get("success") is False:
            errors = (
                data.get("errors")
                or data.get("error")
                or "Request failed"
            )
            raise APIError(errors)

        return data

    def get(self, path):
        return self._request("GET", path)

    def post(self, path, payload):
        return self._request("POST", path, payload)

    def patch(self, path, payload=None):
        return self._request("PATCH", path, payload or {})

    def delete(self, path):
        return self._request("DELETE", path)
