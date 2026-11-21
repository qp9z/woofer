# Prompt for executing the P3 plan

Paste everything below the line into a new Claude Code session (Sonnet, medium
effort), started in `C:\Users\Pc\se\projects\woofer`.

---

Execute the approved plan in `docs/plans/P3_UX_PLAN.md` from start to finish. It is already approved: do not re-plan, do not ask for approval, do not enter plan mode.

Before you start:
1. Read `CLAUDE.md` and then `docs/plans/P3_UX_PLAN.md` in full. The plan's "Rules for the executor" section is mandatory. Re-read it before each step.
2. Run the plan's branch setup (`git checkout main`, `git pull`, `git checkout -b p3-ux`). The two files in `docs/plans/` are untracked. Include them in your Step 1 commit so the plan lives in history.
3. Run a baseline from `app/`: `flutter analyze` and `flutter test`. Expect no issues and 129 passing tests. If the baseline isn't green, stop and report before changing anything.

How to work:
- Do Steps 1–10 in order, with exactly one local commit per step, using the commit titles the plan gives. Before each commit, `flutter analyze` must be clean and `flutter test` all green. Do not push. I approve pushes myself.
- Use the Bash tool (Git Bash) for commands. If you ever give me commands to run myself, write them as separate lines: my Windows PowerShell 5.1 does not support `&&`.
- For Gradle, set `JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"`. Gradle 8.14 fails on the system JDK 25 with just "25.0.2".
- Follow the code shapes in the plan (`TapTarget`, `reduceMotion`, `pumpApp`, the migration, `shareRejectedProvider`, the `HomeShell` listener) as written. Use only existing design tokens. Add no new dependencies.
- Do every mutation check the plan lists. Break the protected code, confirm the test fails, restore with `git checkout -- <file>`, and confirm `git diff` is empty.
- If something fails for a reason the plan didn't foresee, fix the code, not the assertion. Never weaken or skip a test to get green. If you can't resolve it, stop and tell me exactly what failed and what you tried.
- The test phone is unauthorized in ADB, so skip anything that needs a device. That's the plan's open device-QA item.

When finished, report:
- the list of commits on `p3-ux`;
- the final `flutter analyze` and `flutter test` results, with test counts;
- the result of `./gradlew :app:testDebugUnitTest` and `flutter build apk --release`;
- the outcome of each mutation check;
- any deviation from the plan and why;
- anything left undone.
