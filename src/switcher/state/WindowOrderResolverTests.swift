import XCTest

/// Pins the switcher's window display order: `WindowOrderResolver.isOrderedBefore`. Each test builds
/// two `OrderWindow`s (a `WindowState` snapshot + `ApplicationState` + the query-derived search
/// rank) differing in one fact and asserts the comparator's answer under the right knobs. Pure data
/// in, `Bool` out.
///
/// Groups: A search ranking · B show-at-the-end buckets · C recentlyFocused · D recentlyCreated ·
/// E alphabetical · F space · G tiebreak/symmetry.
final class WindowOrderResolverTests: XCTestCase {

    private func w(searchMatches: Bool = false, searchRelevance: Double = 0,
                   isWindowlessApp: Bool = false, isHidden: Bool = false, isMinimized: Bool = false,
                   isOnAllSpaces: Bool = false, spaceIndexes: [Int] = [], aerospaceId: String? = nil,
                   lastFocusOrder: Int = 0, creationOrder: Int = 0,
                   appName: String = "App", windowTitle: String = "Title") -> OrderWindow {
        let state = WindowState(id: "w", isInvisible: false, isWindowlessApp: isWindowlessApp,
                                isFullscreen: false, isMinimized: isMinimized, isTabbed: false,
                                isOnAllSpaces: isOnAllSpaces, spaceIds: [], spaceIndexes: spaceIndexes,
                                aerospaceId: aerospaceId,
                                lastFocusOrder: lastFocusOrder, creationOrder: creationOrder, title: windowTitle)
        let app = ApplicationState(pid: 0, bundleIdentifier: nil, localizedName: appName, isHidden: isHidden)
        return OrderWindow(state: state, app: app, searchMatches: searchMatches, searchRelevance: searchRelevance)
    }

    // MARK: - A. Search ranking

    func testSearchMatchedSortsBeforeUnmatched() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(searchMatches: true), w(searchMatches: false),
                                                          searchActive: true))
        XCTAssertFalse(WindowOrderResolver.isOrderedBefore(w(searchMatches: false), w(searchMatches: true),
                                                           searchActive: true))
    }

    func testSearchHigherRelevanceSortsFirst() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(searchMatches: true, searchRelevance: 2),
                                                          w(searchMatches: true, searchRelevance: 1),
                                                          searchActive: true))
    }

    func testSearchEqualRelevanceTiebreaksByLastFocusOrder() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(searchMatches: true, searchRelevance: 1, lastFocusOrder: 0),
                                                          w(searchMatches: true, searchRelevance: 1, lastFocusOrder: 1),
                                                          searchActive: true))
    }

    // MARK: - B. Show-at-the-end buckets

    func testWindowlessPushedToEndWhenConfigured() {
        XCTAssertFalse(WindowOrderResolver.isOrderedBefore(w(isWindowlessApp: true), w(isWindowlessApp: false),
                                                           windowlessAtEnd: true))
    }

    func testRealWindowBeforeWindowlessWhenConfigured() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(isWindowlessApp: false), w(isWindowlessApp: true),
                                                          windowlessAtEnd: true))
    }

    func testWindowlessNotSeparatedWhenFlagOff() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(isWindowlessApp: true, lastFocusOrder: 0),
                                                          w(isWindowlessApp: false, lastFocusOrder: 1),
                                                          windowlessAtEnd: false, sortType: .recentlyFocused))
    }

    func testHiddenPushedToEndWhenConfigured() {
        XCTAssertFalse(WindowOrderResolver.isOrderedBefore(w(isHidden: true), w(isHidden: false),
                                                           hiddenAtEnd: true))
    }

    func testMinimizedPushedToEndWhenConfigured() {
        XCTAssertFalse(WindowOrderResolver.isOrderedBefore(w(isMinimized: true), w(isMinimized: false),
                                                           minimizedAtEnd: true))
    }

    // MARK: - C. Recently focused

    func testRecentlyFocusedLowerOrderFirst() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(lastFocusOrder: 0), w(lastFocusOrder: 5),
                                                          sortType: .recentlyFocused))
    }

    // MARK: - D. Recently created

    func testRecentlyCreatedHigherCreationOrderFirst() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(creationOrder: 5), w(creationOrder: 2),
                                                          sortType: .recentlyCreated))
    }

    // MARK: - E. Alphabetical

    func testAlphabeticalByAppName() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(appName: "Aaa"), w(appName: "Bbb"),
                                                          sortType: .alphabetical))
    }

    func testAlphabeticalTitleBreaksTieWithinSameApp() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(appName: "Same", windowTitle: "Alpha"),
                                                          w(appName: "Same", windowTitle: "Beta"),
                                                          sortType: .alphabetical))
    }

    func testAlphabeticalTiebreaksByLastFocusOrder() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(lastFocusOrder: 0, appName: "Same", windowTitle: "Same"),
                                                          w(lastFocusOrder: 1, appName: "Same", windowTitle: "Same"),
                                                          sortType: .alphabetical))
    }

    // MARK: - F. Space

    func testSpaceAeroSpaceIdSortsBeforeMissingId() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(aerospaceId: "2"),
                                                          w(aerospaceId: nil),
                                                          sortType: .space))
    }

    func testSpaceAeroSpaceIdSortsLexicographically() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(aerospaceId: "1"), w(aerospaceId: "2"),
                                                          sortType: .space))
    }

    func testSpaceTiebreaksByAppName() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(aerospaceId: "1", appName: "Aaa"),
                                                          w(aerospaceId: "1", appName: "Bbb"),
                                                          sortType: .space))
    }

    /// Matching AeroSpace workspaces fall through to the alphabetical tiebreak.
    func testSpaceSameAeroSpaceIdTiebreaksByAppName() {
        XCTAssertTrue(WindowOrderResolver.isOrderedBefore(w(aerospaceId: "1", appName: "Aaa"),
                                                          w(aerospaceId: "1", appName: "Bbb"),
                                                          sortType: .space))
        XCTAssertFalse(WindowOrderResolver.isOrderedBefore(w(aerospaceId: "1", appName: "Bbb"),
                                                           w(aerospaceId: "1", appName: "Aaa"),
                                                           sortType: .space))
    }

    /// Symmetric to `testSpaceAeroSpaceIdSortsBeforeMissingId`: a missing workspace sorts after
    /// a known workspace, regardless of argument order.
    func testSpaceKnownAeroSpaceIdSortsBeforeMissingIdWhenKnownIdIsSecond() {
        XCTAssertFalse(WindowOrderResolver.isOrderedBefore(w(aerospaceId: nil),
                                                           w(aerospaceId: "2"),
                                                           sortType: .space))
    }

    // MARK: - G. Tiebreak / symmetry

    func testEqualWindowsAreNotOrderedBeforeEachOther() {
        let a = w(lastFocusOrder: 3)
        XCTAssertFalse(WindowOrderResolver.isOrderedBefore(a, a, sortType: .recentlyFocused))
    }
}
