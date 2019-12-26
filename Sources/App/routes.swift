import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    // 1
    let acronymsController = AcronymsController()
    // 2
    try router.register(collection: acronymsController)

    let userController = UsersController()
    try router.register(collection: userController)

    let categoriesController = CategoriesController()
    try router.register(collection: categoriesController)

    let websiteController = WebsiteController()
    try router.register(collection: websiteController)
}


