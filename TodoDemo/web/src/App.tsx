import * as React from "react";
import {useEffect, useState} from "react";
import {addTodo, listTodos, removeTodo, type Todo, toggleTodo} from "./api";
import {useTodoUpdates} from "./useTodoUpdates.ts";

export default function App() {
    const [todos, setTodos] = useState<Todo[]>([]);
    const [title, setTitle] = useState("");

    async function refresh() {
        setTodos(await listTodos());
    }

    useEffect(() => {
        refresh().then();
    }, []);

    useTodoUpdates((type, payload) => {
        if (type === "add") setTodos(prev => [...prev, payload]);
        if (type === "update")
            setTodos(prev =>
                prev.map(t => (t.id === payload.id ? payload : t))
            );
        if (type === "delete")
            setTodos(prev => prev.filter(t => t.id !== payload));
    });

    async function onAdd(e: React.FormEvent) {
        e.preventDefault();
        if (!title.trim()) return;
        await addTodo(title.trim());
        setTitle("");
    }

    return (
        <main style={{maxWidth: 640, margin: "40px auto", padding: 16, fontFamily: "sans-serif"}}>
            <h1>(React + TS)</h1>
            <form onSubmit={onAdd} style={{display: "flex", gap: 8}}>
                <input
                    value={title}
                    onChange={e => setTitle(e.target.value)}
                    placeholder="新事项"
                    style={{flex: 1, padding: 8}}
                />
                <button type="submit">添加</button>
            </form>

            <ul style={{marginTop: 16, padding: 0, listStyle: "none"}}>
                {todos.map(t => (
                    <li key={t.id} style={{
                        display: "flex", alignItems: "center", gap: 8,
                        padding: "8px 0", borderBottom: "1px solid #eee"
                    }}>
                        <input type="checkbox" checked={t.isDone} onChange={async () => {
                            await toggleTodo(t.id);
                        }}/>
                        <span style={{textDecoration: t.isDone ? "line-through" : "none"}}>{t.title}</span>
                        <button style={{marginLeft: "auto"}} onClick={async () => {
                            await removeTodo(t.id);
                        }}>删除
                        </button>
                    </li>
                ))}
            </ul>
        </main>
    );
}
