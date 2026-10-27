import { makeHandler } from "../_shared/handler.ts";
import { realServices } from "../_shared/services.ts";
import { spec } from "./handler.ts";

Deno.serve(makeHandler(spec, realServices));
