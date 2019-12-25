//
//  CategoriesController.swift
//  App
//
//  Created by tstone10 on 2019/12/25.
//

import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let categoriesRouter = router.grouped("api", "categories")

        categoriesRouter.get(use: getAllHandler)
        categoriesRouter.get(Category.parameter, use: getHandler)
        categoriesRouter.post(Category.self, use: createHandler)
        categoriesRouter.get(Category.parameter, "acronyms", use: getAcronymsHandler)
    }

    func createHandler(_ req: Request, category: Category) throws -> Future<Category> {
        return category.save(on: req)
    }

    func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category.query(on: req).all()
    }

    func getHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameters.next(Category.self)
    }

    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(Category.self)
            .flatMap(to: [Acronym].self) { category in
                return try category.acronym.query(on: req).all()
        }
    }
}
