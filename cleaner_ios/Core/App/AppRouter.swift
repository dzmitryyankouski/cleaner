import SwiftUI
import Observation

enum AppRoute: Hashable {
    case smartCleanup
}

@Observable
final class AppRouter {
    var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }
}
