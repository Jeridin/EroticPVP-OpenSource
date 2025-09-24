import { useEffect, useRef } from "react";
import { noop } from "../utils/misc";

interface NuiMessageData<T = unknown> {
  action: string;
  data: T;
}

type NuiHandlerSignature<T> = (data: T) => void;

/**
 * A hook that manages event listeners for receiving data from the client scripts
 * @param action The specific `action` that should be listened for.
 * @param handler The callback function that will handle data relayed by this hook
 */
export const useNuiEvent = <T = unknown>(
  action: string,
  handler: NuiHandlerSignature<T>
): void => {
  // useRef<T>(...) returns RefObject<T>, but we can safely mutate `.current`
  const savedHandler = useRef<NuiHandlerSignature<T>>(noop);

  // Keep the latest handler in ref
  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const eventListener = (event: MessageEvent) => {
      const message = event.data as Partial<NuiMessageData<T>>;
      if (message?.action === action && message.data !== undefined) {
        savedHandler.current(message.data as T);
      }
    };

    window.addEventListener("message", eventListener);
    return () => window.removeEventListener("message", eventListener);
  }, [action]);
};
