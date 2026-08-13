# The Cause

Fly GACA exists to **make every Saudi aviation regulation authoritative, bilingual, and
instantly accessible** — to every pilot, cadet, instructor and dispatcher in the Kingdom, on
every device they own, with or without a signal.

*find it · study it · always verify against GACA*

## The problem

Saudi civil aviation runs on the GACARs — the General Authority of Civil Aviation Regulations —
plus the AIP, and a working pilot is expected to know them cold. But studying them is harder
than it should be: the material is scattered across large official publications, written almost
entirely in English legalese, and not shaped for exam prep, review or quick lookup. Cadets
cram from photocopied question banks of unknown provenance; instructors rebuild the same study
sheets from scratch; answers circulate without citations, so nobody can tell a rule from a
rumor. The regulation itself is public — the *access* is what's broken.

## What we build

One cause, three surfaces:

- **flygaca.com** — the open regulatory library and study platform: the corpus, search, guides,
  flight tools, study packs and the reader, free to browse. The web monorepo
  ([FlyGACA/FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app)) is the source of truth for
  the corpus and the pack catalog.
- **Captain Adel** — the AI flight instructor ([captadel.com](https://captadel.com)): answers
  GACAR questions with exact Part/section citations, and refuses to guess when it can't ground
  an answer in the regulations.
- **This repo** — the native iOS family: one shared Swift package, one App Store app per study
  module (ELPT, AIP), every one of them fully usable offline. A module is data, not code.

## Principles

The same seven principles hold across every Fly GACA repo and surface:

- **Independent and educational, not regulatory.** We are not GACA. We help people find and
  study regulation; we never replace it, and every surface says so.
- **Citations or silence.** An answer that can't name its Part and section doesn't ship.
  Captain Adel refuses rather than guesses; study content cites its source.
- **Bilingual or it didn't ship.** Arabic is a first-class language, not a translation pass —
  RTL layouts, Arabic content, and parity checks that fail the build when one language falls
  behind.
- **Offline is a feature.** A cadet in a crew room with no signal still gets the full product.
  The web app works offline; the iOS apps are offline *by design*.
- **In-Kingdom by default.** User data stays under Saudi jurisdiction (PDPL): in-Kingdom
  hosting and regions for anything that touches a real user's questions or progress.
- **Never paywall the regulations.** The corpus stays free to read on flygaca.com. What is
  sold is the study toolchain around it — packs, tools, the native apps — never access to the
  law itself.
- **The disclaimer is a discipline.** The not-affiliated-with-GACA statement is load-bearing,
  verbatim, on every surface — a footnote nowhere, a rule everywhere.

## What this means for the native apps

This repo is the cause compiled for the flight bag:

- **Offline-first is the product.** Every app bundles its whole module — banks, lessons, exam
  config — and works with airplane mode on. No account, no network, no excuses.
- **One family on one device.** The shared App Group (`group.com.FlyGACA`) carries
  streaks, spaced repetition and progress across every app in the family, so buying the next
  rating doesn't mean starting over.
- **Web-parity semantics.** Spaced repetition, exam scoring and streaks are literal ports of
  the web contracts, guarded by parity test vectors — a student moving between phone and
  browser is always studying against the same rules.
- **Paid apps, free law.** The apps are paid-up-front on the App Store; that price buys the
  offline study toolchain. The regulations they teach remain free to everyone on flygaca.com —
  see the principle above.

## Who we are

Fly GACA and Captain Adel are products of **BDA Company International (شركة بدع الدولية)**,
operating as Fly GACA — built in the Kingdom, for the Kingdom's aviators.

## Disclaimer

**Fly GACA is an independent educational platform.** It is not affiliated with, endorsed by, or operated by the General Authority of Civil Aviation (GACA) or the Government of the Kingdom of Saudi Arabia. The official and authoritative source for all civil aviation regulations, publications, and aeronautical information is always GACA. Always verify against the latest official GACA publication at gaca.gov.sa.

<div dir="rtl">

**فلاي جاكا منصة تعليمية مستقلة.** وهي غير تابعة للهيئة العامة للطيران المدني (GACA) ولا معتمدة منها ولا تُديرها، كما أنها لا تمثّل حكومة المملكة العربية السعودية. المصدر الرسمي والمعتمد لجميع لوائح الطيران المدني ومنشوراته ومعلوماته الجوية هو GACA دائمًا. تحقّق دائمًا من أحدث منشور رسمي صادر عن GACA على gaca.gov.sa.

</div>
