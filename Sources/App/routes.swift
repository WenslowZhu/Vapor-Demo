import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }

    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // 添加一条记录
    router.post("api", "acronyms") { req -> Future<Acronym> in
        return try req.content.decode(Acronym.self)
            .flatMap(to: Acronym.self) { (acronym) in
                return acronym.save(on: req)
            }
    }

    // 获取所有条目
    router.get("api", "acronyms") { req -> Future<[Acronym]> in
        return Acronym.query(on: req).all()
    }

    // 从 ID 获取一条条目
    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try req.parameters.next(Acronym.self)
    }

    // 更新某条条目
    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self)) { acronym, updatedAcronym in
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            return acronym.save(on: req)
                        }
    }

    // 删除
    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        return try req.parameters.next(Acronym.self)
                .delete(on: req)
                .transform(to: .noContent)
    }

    // 搜索 获取所有条目
    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(HTTPResponseStatus.badRequest)
        }
        return Acronym.query(on: req).group(.or) { (or) in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
            }.all()
    }

    // 搜索获取第一条条目
    router.get("api", "acronyms", "first") { req -> Future<Acronym> in
        return Acronym.query(on: req)
            .first()
            .unwrap(or: Abort(HTTPResponseStatus.notFound))
    }

    // 获取，并排序
    router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
        return Acronym.query(on: req)
            .sort(\.short, ._ascending).all()
    }
}
