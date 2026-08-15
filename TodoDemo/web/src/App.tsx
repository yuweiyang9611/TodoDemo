import {type FormEvent, useCallback, useEffect, useState} from "react";
import "./App.css";
import {addTodo, listTodos, removeTodo, type Todo, toggleTodo} from "./api";
import {
    type ConnectionStatus,
    type TodoEvent,
    useTodoUpdates,
} from "./useTodoUpdates";

const connectionLabels: Record<ConnectionStatus, string> = {
    connecting: "正在连接实时服务",
    connected: "实时同步已连接",
    reconnecting: "实时服务正在重连",
    disconnected: "实时服务已断开",
};

function upsertTodo(items: Todo[], todo: Todo): Todo[] {
    const index = items.findIndex(item => item.id === todo.id);
    if (index < 0) {
        return [...items, todo];
    }

    return items.map(item => item.id === todo.id ? todo : item);
}

function messageFromError(error: unknown): string {
    return error instanceof Error ? error.message : "发生了未知错误。";
}

export default function App() {
    const [todos, setTodos] = useState<Todo[]>([]);
    const [title, setTitle] = useState("");
    const [loading, setLoading] = useState(true);
    const [adding, setAdding] = useState(false);
    const [pendingIds, setPendingIds] = useState<Set<string>>(() => new Set());
    const [error, setError] = useState<string | null>(null);

    const refresh = useCallback(async () => {
        try {
            const nextTodos = await listTodos();
            setTodos(nextTodos);
            setError(null);
        } catch (caught) {
            setError(messageFromError(caught));
        } finally {
            setLoading(false);
        }
    }, []);

    const onRealtimeEvent = useCallback((event: TodoEvent) => {
        switch (event.type) {
            case "added":
            case "updated":
                setTodos(current => upsertTodo(current, event.todo));
                break;
            case "deleted":
                setTodos(current => current.filter(todo => todo.id !== event.id));
                break;
        }
    }, []);

    const connectionStatus = useTodoUpdates(onRealtimeEvent, refresh);

    useEffect(() => {
        void refresh();
    }, [refresh]);

    const setPending = (id: string, pending: boolean) => {
        setPendingIds(current => {
            const next = new Set(current);
            if (pending) {
                next.add(id);
            } else {
                next.delete(id);
            }
            return next;
        });
    };

    const onAdd = async (event: FormEvent) => {
        event.preventDefault();
        const trimmedTitle = title.trim();
        if (!trimmedTitle || adding) {
            return;
        }

        setAdding(true);
        try {
            const todo = await addTodo(trimmedTitle);
            setTodos(current => upsertTodo(current, todo));
            setTitle("");
            setError(null);
        } catch (caught) {
            setError(messageFromError(caught));
        } finally {
            setAdding(false);
        }
    };

    const onToggle = async (id: string) => {
        setPending(id, true);
        try {
            const todo = await toggleTodo(id);
            setTodos(current => upsertTodo(current, todo));
            setError(null);
        } catch (caught) {
            setError(messageFromError(caught));
        } finally {
            setPending(id, false);
        }
    };

    const onDelete = async (id: string) => {
        setPending(id, true);
        try {
            await removeTodo(id);
            setTodos(current => current.filter(todo => todo.id !== id));
            setError(null);
        } catch (caught) {
            setError(messageFromError(caught));
        } finally {
            setPending(id, false);
        }
    };

    return (
        <main className="todo-shell">
            <header className="todo-header">
                <div>
                    <p className="eyebrow">ASP.NET Core · React · SignalR</p>
                    <h1>Todo 学习项目</h1>
                    <p className="subtitle">REST 负责可靠读写，SignalR 负责跨客户端实时通知。</p>
                </div>
                <span className={"connection connection--" + connectionStatus}>
                    <span aria-hidden="true" className="connection__dot"/>
                    {connectionLabels[connectionStatus]}
                </span>
            </header>

            <form className="todo-form" onSubmit={onAdd}>
                <label htmlFor="new-todo">新事项</label>
                <div className="todo-form__controls">
                    <input
                        id="new-todo"
                        maxLength={200}
                        value={title}
                        onChange={event => setTitle(event.target.value)}
                        placeholder="例如：理解 SignalR 重连"
                    />
                    <button disabled={adding || !title.trim()} type="submit">
                        {adding ? "添加中…" : "添加"}
                    </button>
                </div>
            </form>

            {error && (
                <div className="error-banner" role="alert">
                    <span>{error}</span>
                    <button onClick={() => void refresh()} type="button">重试</button>
                </div>
            )}

            <section aria-busy={loading} aria-labelledby="todo-list-title" className="todo-list">
                <div className="todo-list__heading">
                    <h2 id="todo-list-title">事项</h2>
                    <span>{todos.length} 项</span>
                </div>

                {loading ? (
                    <p className="empty-state">正在加载…</p>
                ) : todos.length === 0 ? (
                    <p className="empty-state">暂无事项，添加一条开始学习。</p>
                ) : (
                    <ul>
                        {todos.map(todo => {
                            const pending = pendingIds.has(todo.id);
                            return (
                                <li key={todo.id}>
                                    <label className="todo-item">
                                        <input
                                            checked={todo.isDone}
                                            disabled={pending}
                                            onChange={() => void onToggle(todo.id)}
                                            type="checkbox"
                                        />
                                        <span className={todo.isDone ? "todo-item__title todo-item__title--done" : "todo-item__title"}>
                                            {todo.title}
                                        </span>
                                    </label>
                                    <button
                                        className="delete-button"
                                        disabled={pending}
                                        onClick={() => void onDelete(todo.id)}
                                        type="button"
                                    >
                                        删除
                                    </button>
                                </li>
                            );
                        })}
                    </ul>
                )}
            </section>
        </main>
    );
}
