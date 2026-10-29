
import { ResponseType } from "../_shared/ResponseType.ts";
import { log } from "./Log.ts";

export function sendResponse(response: ResponseType) : Response {

    log("RESPONSE: ", response);
    
    return new Response(
      JSON.stringify(response),
      { headers: { "Content-Type": "application/json" }, status: response.statusCode }
    );
  }