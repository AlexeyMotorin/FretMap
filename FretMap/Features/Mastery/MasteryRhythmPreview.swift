import SwiftUI

/// One 4/4 measure, with beams grouped by quarter-note beat.
struct MasteryRhythmPreview: View {
    let subdivision: PracticeSubdivision

    private var minimumWidth: CGFloat {
        max(280, 64 + CGFloat(4 * subdivision.notesPerBeat) * 14 + 48)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    Canvas { context, size in
                        let ink = Color.primary
                        let baseline: CGFloat = 58
                        let top: CGFloat = 32
                        func line(_ from: CGPoint, _ to: CGPoint, width: CGFloat = 1.5) {
                            var path = Path()
                            path.move(to: from)
                            path.addLine(to: to)
                            context.stroke(path, with: .color(ink), lineWidth: width)
                        }
                        line(CGPoint(x: 8, y: baseline), CGPoint(x: size.width - 8, y: baseline))
                        for x in [CGFloat(8), size.width - 8] {
                            line(CGPoint(x: x, y: 20), CGPoint(x: x, y: 80))
                        }
                        for y in [CGFloat(40), CGFloat(73)] {
                            context.draw(Text("4").font(.system(size: 22, weight: .medium)).foregroundColor(ink),
                                         at: CGPoint(x: 29, y: y))
                        }
                        let groupWidth = (size.width - 66) / 4
                        for beat in 0..<4 {
                            let start = 54 + CGFloat(beat) * groupWidth
                            let spacing = (groupWidth - 15) / CGFloat(subdivision.notesPerBeat)
                            let last = start + CGFloat(subdivision.notesPerBeat - 1) * spacing
                            for note in 0..<subdivision.notesPerBeat {
                                let x = start + CGFloat(note) * spacing
                                var headContext = context
                                headContext.translateBy(x: x, y: baseline)
                                headContext.rotate(by: .degrees(-25))
                                headContext.fill(Path(ellipseIn: CGRect(x: -5, y: -3.5, width: 10, height: 7)),
                                                 with: .color(ink))
                                line(CGPoint(x: x + 4, y: baseline), CGPoint(x: x + 4, y: top))
                            }
                            for beam in 0..<subdivision.beamCount {
                                let y = top + CGFloat(beam) * 6
                                line(CGPoint(x: start + 4, y: y), CGPoint(x: last + 4, y: y), width: 3)
                            }
                            if let tuplet = subdivision.tupletNumber {
                                context.draw(Text(String(tuplet)).font(.system(size: 15, weight: .semibold)).foregroundColor(ink),
                                             at: CGPoint(x: (start + last) / 2 + 4, y: 15))
                            }
                        }
                    }
                    .frame(width: max(geometry.size.width, minimumWidth), height: 90)
                }
            }.frame(height: 100)
            Text("mastery.rhythm.measure").font(.caption2).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.string(subdivision.localizationKey) + ". " + L10n.string("mastery.rhythm.measure")))
    }
}
