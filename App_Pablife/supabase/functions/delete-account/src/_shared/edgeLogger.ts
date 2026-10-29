export type EdgeLogger = (message: string, data?: unknown) => void;

export function createEdgeLogger(prefix: string): EdgeLogger {
  return (message: string, data?: unknown) => {
    const base = `[${prefix}] ${message}`;
    if (data === undefined) {
      console.log(base);
      return;
    }
    console.log(base, data);
  };
}
