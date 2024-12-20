#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to create directories if they don't exist
create_dir() {
  mkdir -p "$1"
}

# Function to create files with content
create_file() {
  local path=$1
  shift
  cat <<EOT > "$path"
$*
EOT
}

# Create model
create_dir src/database/models
create_file src/database/models/serviceCompany.ts \
"import mongoose from 'mongoose';

interface IServiceCompany extends mongoose.Document {
  name: string;
  address: string;
  description?: string;
  map?: string;
  url?: string;
  isActive: boolean;
  isDeleted: boolean;
}

const ServiceCompanySchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    address: { type: String, required: true },
    description: { type: String },
    map: { type: String },
    url: { type: String },
    isActive: { type: Boolean, default: true },
    isDeleted: { type: Boolean, default: false },
  },
  { timestamps: true }
);

export const ServiceCompanyModel = mongoose.model<IServiceCompany>('ServiceCompany', ServiceCompanySchema);
"

# Create repository
create_dir src/database/repositories
create_file src/database/repositories/serviceCompany.ts \
"import { Request } from 'express';
import { ServiceCompanyModel } from '../models/serviceCompany';
import {
  IServiceCompany,
  ICreateServiceCompany,
  IUpdateServiceCompany,
} from '../../interfaces/serviceCompany';
import { logError } from '../../utils/errorLogger';
import { IPagination } from '../../interfaces/pagination';

class ServiceCompanyRepository {
  public async getServiceCompanies(
    req: Request,
    pagination: IPagination,
    search: string
  ): Promise<{
    data: IServiceCompany[];
    totalCount: number;
    currentPage: number;
    totalPages?: number;
  }> {
    try {
      let query: any = {};
      if (search) {
        query.name = { \$regex: search, \$options: 'i' };
      }

      const serviceCompaniesDoc = await ServiceCompanyModel.find(query)
        .limit(pagination.limit)
        .skip((pagination.page - 1) * pagination.limit);

      const serviceCompanies = serviceCompaniesDoc.map((doc) => doc.toObject() as IServiceCompany);

      const totalCount = await ServiceCompanyModel.countDocuments(query);
      const totalPages = Math.ceil(totalCount / pagination.limit);

      return {
        data: serviceCompanies,
        totalCount,
        currentPage: pagination.page,
        totalPages,
      };
    } catch (error) {
      await logError(error, req, 'ServiceCompanyRepository-getServiceCompanies');
      throw error;
    }
  }

  public async getServiceCompanyById(req: Request, id: string): Promise<IServiceCompany> {
    try {
      const serviceCompanyDoc = await ServiceCompanyModel.findById(id);

      if (!serviceCompanyDoc) {
        throw new Error('ServiceCompany not found');
      }

      return serviceCompanyDoc.toObject() as IServiceCompany;
    } catch (error) {
      await logError(error, req, 'ServiceCompanyRepository-getServiceCompanyById');
      throw error;
    }
  }

  public async createServiceCompany(
    req: Request,
    serviceCompanyData: ICreateServiceCompany
  ): Promise<IServiceCompany> {
    try {
      const newServiceCompany = await ServiceCompanyModel.create(serviceCompanyData);
      return newServiceCompany.toObject();
    } catch (error) {
      await logError(error, req, 'ServiceCompanyRepository-createServiceCompany');
      throw error;
    }
  }

  public async updateServiceCompany(
    req: Request,
    id: string,
    serviceCompanyData: Partial<IUpdateServiceCompany>
  ): Promise<IServiceCompany> {
    try {
      const updatedServiceCompany = await ServiceCompanyModel.findByIdAndUpdate(
        id,
        serviceCompanyData,
        { new: true }
      );
      if (!updatedServiceCompany) {
        throw new Error('Failed to update ServiceCompany');
      }
      return updatedServiceCompany.toObject();
    } catch (error) {
      await logError(error, req, 'ServiceCompanyRepository-updateServiceCompany');
      throw error;
    }
  }

  public async deleteServiceCompany(req: Request, id: string): Promise<IServiceCompany> {
    try {
      const deletedServiceCompany = await ServiceCompanyModel.findByIdAndDelete(id);
      if (!deletedServiceCompany) {
        throw new Error('Failed to delete ServiceCompany');
      }
      return deletedServiceCompany.toObject();
    } catch (error) {
      await logError(error, req, 'ServiceCompanyRepository-deleteServiceCompany');
      throw error;
    }
  }
}

export default ServiceCompanyRepository;
"

# Create service
create_dir src/services
create_file src/services/serviceCompany.ts \
"import { Request, Response } from 'express';
import ServiceCompanyRepository from '../database/repositories/serviceCompany';
import { logError } from '../utils/errorLogger';
import { paginationHandler } from '../utils/paginationHandler';
import { searchHandler } from '../utils/searchHandler';

class ServiceCompanyService {
  private serviceCompanyRepository: ServiceCompanyRepository;

  constructor() {
    this.serviceCompanyRepository = new ServiceCompanyRepository();
  }

  public async getServiceCompanies(req: Request, res: Response) {
    try {
      const pagination = paginationHandler(req);
      const search = searchHandler(req);
      const serviceCompanies = await this.serviceCompanyRepository.getServiceCompanies(
        req,
        pagination,
        search
      );
      res.sendArrayFormatted(serviceCompanies, 'ServiceCompanies retrieved successfully');
    } catch (error) {
      await logError(error, req, 'ServiceCompanyService-getServiceCompanies');
      res.sendError(error, 'ServiceCompanies retrieval failed');
    }
  }

  public async getServiceCompany(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const serviceCompany = await this.serviceCompanyRepository.getServiceCompanyById(req, id);
      res.sendFormatted(serviceCompany, 'ServiceCompany retrieved successfully');
    } catch (error) {
      await logError(error, req, 'ServiceCompanyService-getServiceCompany');
      res.sendError(error, 'ServiceCompany retrieval failed');
    }
  }

  public async createServiceCompany(req: Request, res: Response) {
    try {
      const serviceCompanyData = req.body;
      const newServiceCompany = await this.serviceCompanyRepository.createServiceCompany(req, serviceCompanyData);
      res.sendFormatted(newServiceCompany, 'ServiceCompany created successfully', 201);
    } catch (error) {
      await logError(error, req, 'ServiceCompanyService-createServiceCompany');
      res.sendError(error, 'ServiceCompany creation failed');
    }
  }

  public async updateServiceCompany(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const serviceCompanyData = req.body;
      const updatedServiceCompany = await this.serviceCompanyRepository.updateServiceCompany(
        req,
        id,
        serviceCompanyData
      );
      res.sendFormatted(updatedServiceCompany, 'ServiceCompany updated successfully');
    } catch (error) {
      await logError(error, req, 'ServiceCompanyService-updateServiceCompany');
      res.sendError(error, 'ServiceCompany update failed');
    }
  }

  public async deleteServiceCompany(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const deletedServiceCompany = await this.serviceCompanyRepository.deleteServiceCompany(req, id);
      res.sendFormatted(deletedServiceCompany, 'ServiceCompany deleted successfully');
    } catch (error) {
      await logError(error, req, 'ServiceCompanyService-deleteServiceCompany');
      res.sendError(error, 'ServiceCompany deletion failed');
    }
  }
}

export default ServiceCompanyService;
"

# Create middleware
create_dir src/middlewares
create_file src/middlewares/serviceCompany.ts \
"import { Request, Response, NextFunction } from 'express';
import { logError } from '../utils/errorLogger';

class ServiceCompanyMiddleware {
  public async createServiceCompany(req: Request, res: Response, next: NextFunction) {
    try {
      const { name, address } = req.body;
      if (!name || !address) {
        res.sendError(
          'ValidationError: Name and Address must be provided',
          'Name and Address must be provided',
          400
        );
        return;
      }
      next();
    } catch (error) {
      await logError(error, req, 'Middleware-ServiceCompanyCreate');
      res.sendError(error, 'An unexpected error occurred', 500);
    }
  }

  public async updateServiceCompany(req: Request, res: Response, next: NextFunction) {
    try {
      const { name, address } = req.body;
      if (!name && !address) {
        res.sendError(
          'ValidationError: At least one field (Name or Address) must be provided',
          'At least one field (Name or Address) must be provided',
          400
        );
        return;
      }
      next();
    } catch (error) {
      await logError(error, req, 'Middleware-ServiceCompanyUpdate');
      res.sendError(error, 'An unexpected error occurred', 500);
    }
  }

  public async deleteServiceCompany(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      if (!id) {
        res.sendError(
          'ValidationError: ID must be provided',
          'ID must be provided',
          400
        );
        return;
      }
      next();
    } catch (error) {
      await logError(error, req, 'Middleware-ServiceCompanyDelete');
      res.sendError(error, 'An unexpected error occurred', 500);
    }
  }
}

export default ServiceCompanyMiddleware;
"

# Create interface
create_dir src/interfaces
create_file src/interfaces/serviceCompany.ts \
"export interface IServiceCompany {
  name: string;
  address: string;
  description?: string;
  map?: string;
  url?: string;
  isActive: boolean;
  isDeleted: boolean;
}

export interface ICreateServiceCompany {
  name: string;
  address: string;
  description?: string;
  map?: string;
  url?: string;
}

export interface IUpdateServiceCompany {
  name?: string;
  address?: string;
  description?: string;
  map?: string;
  url?: string;
}
"

# Create routes
create_dir src/routes
create_file src/routes/serviceCompanyRoute.ts \
"import { Router } from 'express';
import ServiceCompanyService from '../services/serviceCompany';
import ServiceCompanyMiddleware from '../middlewares/serviceCompany';

const serviceCompanyRoute = Router();
const serviceCompanyService = new ServiceCompanyService();
const serviceCompanyMiddleware = new ServiceCompanyMiddleware();

serviceCompanyRoute.get('/', serviceCompanyService.getServiceCompanies.bind(serviceCompanyService));
serviceCompanyRoute.get(
  '/:id',
  serviceCompanyMiddleware.deleteServiceCompany.bind(serviceCompanyMiddleware),
  serviceCompanyService.getServiceCompany.bind(serviceCompanyService)
);
serviceCompanyRoute.post(
  '/',
  serviceCompanyMiddleware.createServiceCompany.bind(serviceCompanyMiddleware),
  serviceCompanyService.createServiceCompany.bind(serviceCompanyService)
);
serviceCompanyRoute.patch(
  '/:id',
  serviceCompanyMiddleware.updateServiceCompany.bind(serviceCompanyMiddleware),
  serviceCompanyService.updateServiceCompany.bind(serviceCompanyService)
);
serviceCompanyRoute.delete(
  '/:id',
  serviceCompanyMiddleware.deleteServiceCompany.bind(serviceCompanyMiddleware),
  serviceCompanyService.deleteServiceCompany.bind(serviceCompanyService)
);

export default serviceCompanyRoute;
"

# Completion Message
echo "ServiceCompany module generated successfully."
