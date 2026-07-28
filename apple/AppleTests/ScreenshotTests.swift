import XCTest

// NOTE: this target is not yet wired into apple/project.yml's `testTargets` (every
// app currently declares `testTargets: []`) — see SCREENSHOTS.md. Adding it needs a
// `type: bundle.ui-testing` target + a per-app `scheme.testTargets` override, which
// is Mac/XcodeGen-side work (no Xcode toolchain to verify it here). Until then this
// file documents the intended flow but cannot run via `xcodebuild test`.
//
// The element lookups below are written against the real ModuleHomeView.swift /
// QuizView.swift / FlashcardView.swift structure (a `List` of `Section`s, no
// dedicated "start exam" step, MCQ choices show the question's real option text
// rather than fixed "A"/"B"/"C"/"D" labels) rather than fixed row indices, since
// row counts differ per app (only modules with ground-school content show a
// "Study" section).
final class ScreenshotTests: XCTestCase {
  let app = XCUIApplication()

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    setupSnapshot(app)
    app.launch()
  }

  func testCaptureHomeScreen() {
    // Home is a List: "Study" (only for modules with ground-school lessons),
    // "Quiz by topic", "Flashcards" and "Exam" sections (ModuleHomeView.swift).
    snapshot("01-home-portrait")
  }

  func testCaptureQuizFlow() {
    snapshot("02-quiz-banks-portrait")

    let firstQuizBank = firstQuestionBankRow()
    XCTAssertTrue(firstQuizBank.waitForExistence(timeout: 5))
    firstQuizBank.tap()
    sleep(2)
    snapshot("03-quiz-question-portrait")
  }

  func testCaptureFlashcardFlow() {
    let header = app.staticTexts["Flashcards"]
    XCTAssertTrue(header.waitForExistence(timeout: 5))
    firstCell(below: header).tap()
    sleep(1)
    snapshot("04-flashcard-front-portrait")

    // The card itself is the tap target that flips it (FlashcardView.swift).
    app.buttons.element(boundBy: 0).tap()
    sleep(1)
    snapshot("05-flashcard-back-portrait")
  }

  func testCaptureMockExamResults() {
    // "Mock exam (untimed)" navigates straight into the quiz — there is no
    // separate "start" step (ModuleHomeView.swift / QuizView.swift).
    app.staticTexts["Mock exam (untimed)"].tap()
    sleep(2)
    answerUntilFinished()
    sleep(1)
    snapshot("06-mock-exam-results-portrait")
  }

  func testCaptureTimedExamFlow() {
    // The label includes the module's config, e.g. "Timed exam — 30 min, pass
    // 75%" (ModuleHomeView.swift), so match by prefix rather than full text.
    let timedExam = app.staticTexts
      .matching(NSPredicate(format: "label BEGINSWITH 'Timed exam'"))
      .element(boundBy: 0)
    XCTAssertTrue(timedExam.waitForExistence(timeout: 5))
    timedExam.tap()
    sleep(1)
    snapshot("07-timed-exam-start-portrait")
    snapshot("08-timed-exam-timer-active-portrait")
  }

  func testCaptureLessonsFlow() throws {
    // Only present for modules with ground-school content (e.g. PPL).
    let header = app.staticTexts["Study"]
    guard header.waitForExistence(timeout: 5) else {
      throw XCTSkip("This module has no Study section.")
    }
    firstCell(below: header).tap()
    sleep(1)
    snapshot("09-lessons-list-portrait")

    app.cells.element(boundBy: 0).tap()
    sleep(1)
    snapshot("10-lesson-content-portrait")
  }

  func testCaptureLandscapeQuiz() {
    XCUIDevice.shared.orientation = .landscapeLeft
    sleep(1)

    let firstQuizBank = firstQuestionBankRow()
    XCTAssertTrue(firstQuizBank.waitForExistence(timeout: 5))
    firstQuizBank.tap()
    sleep(2)

    snapshot("11-quiz-question-landscape")
  }

  // MARK: - Helpers

  /// Bank rows under "Quiz by topic" carry a "<N> questions" caption
  /// (ModuleHomeView.swift's per-bank `NavigationLink` label) — the only rows
  /// on the home screen with that text, so this finds one without depending
  /// on section order or row count.
  private func firstQuestionBankRow() -> XCUIElement {
    app.staticTexts
      .matching(NSPredicate(format: "label CONTAINS[c] ' questions'"))
      .element(boundBy: 0)
  }

  /// The first `cells` row positioned below `header` — a section-order-
  /// independent way to reach "the first row of this section" for sections
  /// (Study, Flashcards) whose rows are plain titles with no distinguishing
  /// caption text of their own.
  private func firstCell(below header: XCUIElement) -> XCUIElement {
    let headerTop = header.frame.minY
    return app.cells.allElementsBoundByIndex.first { $0.frame.minY > headerTop }
      ?? app.cells.element(boundBy: 0)
  }

  /// Answers each question with its first choice and advances (button reads
  /// "Next", then "Finish" on the last question — QuizView.swift), capped so a
  /// UI mismatch fails fast instead of hanging the run.
  private func answerUntilFinished(maxQuestions: Int = 30) {
    for _ in 0..<maxQuestions {
      guard app.buttons["Next"].exists || app.buttons["Finish"].exists else { break }
      app.buttons.element(boundBy: 0).tap() // first answer choice
      sleep(1)
      if app.buttons["Finish"].exists {
        app.buttons["Finish"].tap()
        return
      }
      if app.buttons["Next"].exists {
        app.buttons["Next"].tap()
        sleep(1)
      }
    }
  }

  private func snapshot(_ name: String) {
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}

// MARK: - Snapshot Setup Helper
func setupSnapshot(_ app: XCUIApplication) {
  setLanguage("en")
  app.launchArguments += [
    "-com.apple.dt.XCTestDynamicallyInstantiateClasses",
    "NO"
  ]
}

func setLanguage(_ language: String) {
  UserDefaults.standard.set([language], forKey: "AppleLanguages")
  UserDefaults.standard.synchronize()
}
