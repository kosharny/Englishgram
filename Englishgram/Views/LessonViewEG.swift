import SwiftUI

struct LessonViewEG: View {
    @ObservedObject var model: ViewModelEG
    let topic: TopicEG
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BadgeEG(title: L10nEG.string("ЛЕКЦИЯ"), color: PaletteEG.red)
                Text(topic.title).font(.system(.largeTitle, design: .rounded, weight: .black)).foregroundStyle(PaletteEG.navy)
                ForEach(topic.lecture) { block in LessonBlockViewEG(block: block) }
                PrimaryButtonEG(title: L10nEG.string("Перейти к тесту"), icon: "arrow.right") {
                    model.completeLecture(topic)
                    dismiss()
                    model.start(topic, stage: .choice)
                }.padding(.top, 4)
                Text("За первую лекцию +20 XP").font(.footnote).foregroundStyle(PaletteEG.secondary).frame(maxWidth: .infinity)
            }.padding(20)
        }.screenEG().navigationTitle("Лекция").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
}

struct LessonBlockViewEG: View {
    let block: LessonBlockEG
    var body: some View {
        Group {
            switch block.kind {
            case .formula:
                VStack(alignment: .leading, spacing: 12) {
                    Text(block.title).font(.caption.bold()).foregroundStyle(PaletteEG.red)
                    Text(block.text).font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(PaletteEG.navy).lineSpacing(8)
                }.cardEG()
            case .example:
                HStack(alignment: .top, spacing: 14) {
                    RoundedRectangle(cornerRadius: 2).fill(PaletteEG.red).frame(width: 3)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(block.text).font(.title3.weight(.semibold))
                        if let detail = block.detail { Text(detail).font(.body).foregroundStyle(PaletteEG.secondary) }
                    }
                }.fixedSize(horizontal: false, vertical: true).padding(.vertical, 8)
            case .mistake:
                VStack(alignment: .leading, spacing: 14) {
                    Label(block.title, systemImage: "lightbulb.fill").font(.headline)
                    Label(block.text, systemImage: "xmark.circle.fill").foregroundStyle(PaletteEG.red)
                    if let detail = block.detail { Label(detail, systemImage: "checkmark.circle.fill").foregroundStyle(PaletteEG.success) }
                }.cardEG()
            case .words:
                VStack(alignment: .leading, spacing: 12) {
                    Text(block.title).font(.headline)
                    FlowLayoutEG { ForEach(block.text.components(separatedBy: " • "), id: \.self) { BadgeEG(title: $0) } }
                }.padding(.vertical, 8)
            case .tip, .summary:
                VStack(alignment: .leading, spacing: 12) {
                    Label(block.title, systemImage: block.kind == .tip ? "sparkle" : "bookmark.fill").font(.headline).foregroundStyle(PaletteEG.navy)
                    Text(block.text).font(.body).lineSpacing(5)
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(PaletteEG.subtle, in: RoundedRectangle(cornerRadius: 22))
            case .checkpoint:
                VStack(alignment: .leading, spacing: 14) {
                    Label(block.title, systemImage: "brain.head.profile")
                        .font(.headline).foregroundStyle(PaletteEG.navy)
                    Text(block.text).font(.body).lineSpacing(4)
                    DisclosureGroup("Показать ответ и объяснение") {
                        if let detail = block.detail {
                            Text(detail).font(.body).lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)
                        }
                    }.font(.subheadline.weight(.semibold)).tint(PaletteEG.navy)
                }.cardEG()
            case .text:
                VStack(alignment: .leading, spacing: 12) {
                    Text(block.title).font(.title3.bold())
                    Text(block.text).font(.body).lineSpacing(6)
                }.padding(.vertical, 6)
            }
        }.fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    let model = ViewModelEG(preview: true)
    NavigationStack { if let topic = model.topics.first { LessonViewEG(model: model, topic: topic) } }
}
