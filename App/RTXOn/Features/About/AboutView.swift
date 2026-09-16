import RTXOnCore
import SwiftUI

struct AboutView: View {
    @Environment(AppState.self) private var appState
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "About")
                    Text("How it works")
                        .font(Theme.display(34, weight: .black))
                        .foregroundStyle(Theme.textPrimary)
                }

                section("The tracer", """
                Every tap re-traces the whole board. Each emitter starts a ray; rays walk cell by cell until they hit a wall, \
                a target, or the edge. Mirrors reflect (/ and \\), splitters both reflect and pass, filters keep only the colour \
                components they share with the beam. Targets accumulate colour additively, so red + green lights a yellow target. \
                A ray is keyed on (cell, direction, colour), so splitter loops terminate.
                """)
                section("RTX ON / OFF", """
                The switch in the top right changes only the rendering. OFF draws flat rasterised lines. ON draws the same trace \
                with a soft core, a pulse, and a Metal bloom shader (SwiftUI layerEffect) so beams bleed light into the board.
                """)
                section("Daily", """
                The daily board is generated from the day number with a SplitMix64 PRNG, so everyone gets the same puzzle. \
                Difficulty ramps through the week. Share cards show which cells were lit, never where the optics went.
                """)
                section("Chapters", Chapter.campaign.map { "\($0.name) (\($0.year.map(String.init) ?? "")) — \($0.mechanic)" }.joined(separator: "\n"))
                section("Colophon", """
                Built with Devin as a demo of a native Swift/SwiftUI app, verified on the iOS Simulator from a macOS session. \
                Game logic is a Foundation-only Swift package with tests that run on Linux. Not affiliated with or endorsed by NVIDIA; \
                architecture names are used as chapter titles in tribute.
                """)

                Button(role: .destructive) { confirmReset = true } label: {
                    Text("Reset progress")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Theme.danger)
                        .card()
                }
                .buttonStyle(.plain)
                .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("Reset", role: .destructive) { appState.resetProgress() }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.textPrimary)
            Text(body).font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .card()
    }
}
