export const API_URL = "http://localhost:5200/api";
export type Todo = { id: number; title: string; isDone: boolean };

export async function listTodos(): Promise<Todo[]> {
    const result = await fetch(`${API_URL}/todos`, {cache: 'no-store'});
    if (!result.ok) throw new Error("Failed to fetch todos");
    return result.json();
}

export async function addTodo(title: string): Promise<Todo> {
    // 发出POST请求，内容用json格式承载
    const result = await fetch(`${API_URL}/todos`, {
        method: "POST",
        headers: {"content-type": "application/json"},
        body: JSON.stringify({title}),
    });

    if (!result.ok) throw new Error("add failed");
    return result.json();
}

export async function toggleTodo(id: number): Promise<Todo> {
    const result = await fetch(`${API_URL}/todos/${id}/toggle`, {method: "PUT"});
    if (!result.ok) throw new Error("toggle failed");
    return result.json();
}

export async function removeTodo(id: number): Promise<void> {
    const result = await fetch(`${API_URL}/todos/${id}`, {method: "DELETE"});
    if (!result.ok) throw new Error("delete failed");
}