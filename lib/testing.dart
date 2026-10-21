/// Testing helpers for apps that use go_router.
///
/// * [MockGoRouter] records navigation calls for fast widget tests.
/// * [isAt], [expectRoute] and [expectRedirect] check where a router is.
/// * [openDeepLink] and [expectDeepLink] deliver links the way the operating
///   system does.
library;

export 'src/testing/mock_go_router.dart';
export 'src/testing/router_matchers.dart';
