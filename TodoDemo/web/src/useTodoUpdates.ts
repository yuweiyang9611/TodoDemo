import {useEffect, useState} from "react";
import * as signalR from "@microsoft/signalr";
import {HUB_URL, parseTodo, type Todo} from "./api";

export type TodoEvent =
    | {type: "added"; todo: Todo}
    | {type: "updated"; todo: Todo}
    | {type: "deleted"; id: string};

export type ConnectionStatus =
    | "connecting"
    | "connected"
    | "reconnecting"
    | "disconnected";

const initialRetryDelayMs = 2_000;

export function useTodoUpdates(
    onEvent: (event: TodoEvent) => void,
    onReconnected: () => void | Promise<void>,
): ConnectionStatus {
    const [status, setStatus] = useState<ConnectionStatus>("connecting");

    useEffect(() => {
        let disposed = false;
        let retryTimer: number | undefined;

        const connection = new signalR.HubConnectionBuilder()
            .withUrl(HUB_URL)
            .withAutomaticReconnect()
            .build();

        const handleAdded = (value: unknown) => {
            try {
                onEvent({type: "added", todo: parseTodo(value)});
            } catch (error) {
                console.warn("Ignored an invalid TodoAdded event.", error);
            }
        };
        const handleUpdated = (value: unknown) => {
            try {
                onEvent({type: "updated", todo: parseTodo(value)});
            } catch (error) {
                console.warn("Ignored an invalid TodoUpdated event.", error);
            }
        };
        const handleDeleted = (id: unknown) => {
            if (typeof id === "string") {
                onEvent({type: "deleted", id});
            } else {
                console.warn("Ignored an invalid TodoDeleted event.");
            }
        };

        const scheduleStart = () => {
            if (disposed) {
                return;
            }

            window.clearTimeout(retryTimer);
            retryTimer = window.setTimeout(() => {
                void start();
            }, initialRetryDelayMs);
        };

        const start = async () => {
            if (disposed
                || connection.state !== signalR.HubConnectionState.Disconnected) {
                return;
            }

            setStatus("connecting");
            try {
                await connection.start();
                if (!disposed) {
                    setStatus("connected");
                }
            } catch (error) {
                if (!disposed) {
                    setStatus("disconnected");
                    console.warn("SignalR start failed; retrying.", error);
                    scheduleStart();
                }
            }
        };

        connection.on("TodoAdded", handleAdded);
        connection.on("TodoUpdated", handleUpdated);
        connection.on("TodoDeleted", handleDeleted);
        connection.onreconnecting(() => {
            if (!disposed) {
                setStatus("reconnecting");
            }
        });
        connection.onreconnected(() => {
            if (!disposed) {
                setStatus("connected");
                void Promise.resolve(onReconnected()).catch(error => {
                    console.warn("Unable to refresh after reconnecting.", error);
                });
            }
        });
        connection.onclose(() => {
            if (!disposed) {
                setStatus("disconnected");
                scheduleStart();
            }
        });

        void start();

        return () => {
            disposed = true;
            window.clearTimeout(retryTimer);
            connection.off("TodoAdded", handleAdded);
            connection.off("TodoUpdated", handleUpdated);
            connection.off("TodoDeleted", handleDeleted);
            void connection.stop().catch(error => {
                console.warn("Unable to stop SignalR cleanly.", error);
            });
        };
    }, [onEvent, onReconnected]);

    return status;
}
