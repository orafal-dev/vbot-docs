import { toNextJsHandler } from "better-auth/next-js"

import { getAuth } from "@/lib/auth"

const lazyAuthHandler = (request: Request) => getAuth().handler(request)

export const { GET, POST, PATCH, PUT, DELETE } =
  toNextJsHandler(lazyAuthHandler)
