import SwiftUI
import Observation

enum AppRoute: Hashable {
    case smartCleanup
    case smartCleanupBrowse
}

@Observable
final class AppRouter {
    var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }
}
