import { Request } from "express";

export const paginationHandler = (req: Request) => {
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;
  const page = req.query.page ? parseInt(req.query.page as string) : 1;
  return { limit, page };
};

