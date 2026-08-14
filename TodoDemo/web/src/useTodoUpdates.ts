import {useEffect, useRef} from "react";
import * as signalR from "@microsoft/signalr";
import {type Todo} from "./api";

const hubUrl = "http://localhost:5200/todoHub";

export function useTodoUpdates(onEvent: (type: string, payload: any) => void) {
    const startedRef = useRef(false);
    useEffect(() => {
        if (startedRef.current) return;
        startedRef.current = true;

        const connection = new signalR.HubConnectionBuilder()
            .withUrl(hubUrl)
            .withAutomaticReconnect()
            .build();

        async function start() {
            try {
                await connection.start();
                console.log("✅ SignalR connected");
            } catch (err) {
                console.warn("❌ SignalR failed, retrying in 2s", err);
                setTimeout(start, 2000);
            }
        }

        connection.on("TodoAdded", (todo: Todo) => onEvent("add", todo));
        connection.on("TodoUpdated", (todo: Todo) => onEvent("update", todo));
        connection.on("TodoDeleted", (id: number) => onEvent("delete", id));

        start().then();


        return () => {
            connection.stop().then();
        };
    }, []);
}