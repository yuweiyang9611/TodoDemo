const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL ?? "").replace(/\/+$/, "");

export const HUB_URL = apiBaseUrl + "/todoHub";

export type Todo = {
    id: string;
    title: string;
    isDone: boolean;
};

type JsonObject = Record<string, unknown>;

function isJsonObject(value: unknown): value is JsonObject {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parseTodo(value: unknown): Todo {
    if (!isJsonObject(value)
        || typeof value.id !== "string"
        || typeof value.title !== "string"
        || typeof value.isDone !== "boolean") {
        throw new TypeError("The server returned an invalid todo.");
    }

    return {
        id: value.id,
        title: value.title,
        isDone: value.isDone,
    };
}

function parseTodoList(value: unknown): Todo[] {
    if (!Array.isArray(value)) {
        throw new TypeError("The server returned an invalid todo list.");
    }

    return value.map(parseTodo);
}

export class ApiError extends Error {
    readonly status: number;

    constructor(status: number, message: string) {
        super(message);
        this.name = "ApiError";
        this.status = status;
    }
}

async function errorFromResponse(response: Response): Promise<ApiError> {
    let message = "Request failed (" + response.status + ").";

    try {
        const body: unknown = await response.json();
        if (isJsonObject(body)) {
            if (typeof body.detail === "string") {
                message = body.detail;
            } else if (typeof body.title === "string") {
                message = body.title;
            }
        }
    } catch {
        // A response body is optional for failed requests.
    }

    return new ApiError(response.status, message);
}

async function requestJson<T>(
    path: string,
    init: RequestInit,
    parse: (value: unknown) => T,
): Promise<T> {
    const response = await fetch(apiBaseUrl + path, init);
    if (!response.ok) {
        throw await errorFromResponse(response);
    }

    const body: unknown = await response.json();
    return parse(body);
}

export function listTodos(): Promise<Todo[]> {
    return requestJson("/api/todos", {cache: "no-store"}, parseTodoList);
}

export function addTodo(title: string): Promise<Todo> {
    return requestJson("/api/todos", {
        method: "POST",
        headers: {"content-type": "application/json"},
        body: JSON.stringify({title}),
    }, parseTodo);
}

export function toggleTodo(id: string): Promise<Todo> {
    return requestJson("/api/todos/" + encodeURIComponent(id) + "/toggle", {
        method: "PUT",
    }, parseTodo);
}

export async function removeTodo(id: string): Promise<void> {
    const response = await fetch(
        apiBaseUrl + "/api/todos/" + encodeURIComponent(id),
        {method: "DELETE"},
    );

    if (!response.ok) {
        throw await errorFromResponse(response);
    }
}
