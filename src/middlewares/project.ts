import { Request, Response, NextFunction } from "express";
import Joi from "joi";

class ProjectMiddleware {
  public validateCreate(req: Request, res: Response, next: NextFunction) {
    const schema = Joi.object({
      title: Joi.string().required(),
      description: Joi.string().required(),
      customer: Joi.string().required(),
      location: Joi.string().required(),
      projectManager: Joi.string().required(),
      type: Joi.string().required(),
      task: Joi.string().required(),
      orderNumber: Joi.string().required(),
      assignmentDate: Joi.date().required(),
      schedaRadioDate: Joi.date().required(),
    });

    const { error } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  }

  public validateGet(req: Request, res: Response, next: NextFunction) {
    const schema = Joi.object({
      id: Joi.string().required(),
    });

    const { error } = schema.validate(req.params);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  }

  public validateUpdate(req: Request, res: Response, next: NextFunction) {
    const schema = Joi.object({
      title: Joi.string().optional(),
      description: Joi.string().optional(),
      customId: Joi.string().optional(),
      prevCustomId: Joi.string().optional(),
      customer: Joi.string().optional(),
      admin: Joi.string().optional(),
      manager: Joi.string().optional(),
      status: Joi.string().optional(),
      type: Joi.string().optional(),
      task: Joi.string().optional(),
      orderNumber: Joi.string().optional(),
      assignmentDate: Joi.date().optional(),
      schedaRadioDate: Joi.date().optional(),
      statusHistory: Joi.array().items(Joi.string()).optional(),
      isActive: Joi.boolean().optional(),
      isDeleted: Joi.boolean().optional(),
    });

    const { error } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  }

  public validateDelete(req: Request, res: Response, next: NextFunction) {
    const schema = Joi.object({
      id: Joi.string().required(),
    });

    const { error } = schema.validate(req.params);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  }
}

export default ProjectMiddleware;
