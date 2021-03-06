//
//  AcronymsController.swift
//  App
//
//  Created by tstone10 on 2019/12/23.
//

import Vapor
import Fluent
import Authentication

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")

        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)

//        // 检测密码
//        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
//        let guardAuthMiddleware = User.guardAuthMiddleware()
//        // 使用 中间件
//        let protected = acronymsRoutes.grouped(basicAuthMiddleware,
//                                               guardAuthMiddleware)
        // 取出请求中的 Token
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware,
                                                    guardAuthMiddleware)
        tokenAuthGroup.post(AcronymCreateData.self, use: createHandler)
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
        tokenAuthGroup.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        tokenAuthGroup.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
    }

    // 获取所有条目
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }

    // 新增条目
    func createHandler(_ req: Request, data: AcronymCreateData) throws -> Future<Acronym> {
        let user = try req.requireAuthenticated(User.self)
        let acronym = try Acronym(short: data.short,
                                  long: data.long,
                                  userID: user.requireID())
        return acronym.save(on: req)
    }

    // 获取一条条目
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }

    // 更新一条条目
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(AcronymCreateData.self)) { (acronym, updatedAcronym) in
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            let user = try req.requireAuthenticated(User.self)
                            acronym.userID = try user.requireID()
                            return acronym.save(on: req)
                        }
    }

    // 删除条目
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Acronym.self)
            .delete(on: req)
            .transform(to: .noContent)
    }

    // 搜索条目
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
    }

    // 搜索并获取第一个
    func getFirstHandler(_ req: Request) -> Future<Acronym> {
        return Acronym.query(on: req).first().unwrap(or: Abort(.notFound))
    }

    // 排序
    func sortedHandler(_ req: Request) -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, ._ascending).all()
    }

    // 搜索 Parent
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req
            .parameters
            .next(Acronym.self)
            .flatMap(to: User.Public.self) { acronym in
                acronym.user.get(on: req).convertToPublic()
            }
    }

    // 添加 Categories relationship
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Acronym.self),
                           req.parameters.next(Category.self)) { acronym, category in
                            // 配置关系
                            return acronym.categories.attach(category, on: req)
                                .transform(to: .created)
        }
    }

    // 搜索 Categories
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: [Category].self) { acronym in
                return try acronym.categories.query(on: req).all()
        }
    }

    // 移除关系
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Acronym.self),
                           req.parameters.next(Category.self)) { acronym, category in
                            return acronym.categories.detach(category, on: req)
                                .transform(to: .noContent)

        }
    }
}

struct AcronymCreateData: Content {
    let short: String
    let long: String
}
