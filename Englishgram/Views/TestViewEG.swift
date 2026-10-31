import SwiftUI

struct TestViewEG: View {
    @ObservedObject var model: ViewModelEG
    @State private var confirmPause = false
    var body: some View {
        NavigationStack {
            Group {
                if let result = model.result { ResultViewEG(model: model, result: result) }
                else if let session = model.session {
                    ActiveTestViewEG(model: model, session: session) { confirmPause = true }
                }
            }.screenEG().toolbar(.hidden, for: .navigationBar)
        }.tint(PaletteEG.navy).preferredColorScheme(model.settings.appAppearance.colorScheme).interactiveDismissDisabled()
            .alert("Englishgram", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
                Button("Повторить сохранение") { model.errorMessage = nil; model.save() }
                Button("Понятно", role: .cancel) { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
            .confirmationDialog("Прервать тест?", isPresented: $confirmPause, titleVisibility: .visible) {
                Button("Сохранить и выйти", action: model.pause)
                Button("Продолжить", role: .cancel) { }
            } message: { Text("Ваши ответы сохранятся. Вы сможете продолжить с этого вопроса.") }
    }
}

struct ActiveTestViewEG: View {
    @ObservedObject var model: ViewModelEG
    let session: TestSessionEG
    let close: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(spacing: 0) {
            QuestionHeaderEG(title: session.title, index: session.currentQuestionIndex + 1, total: session.questions.count) { close() }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(session.question.instruction.uppercased()).font(.caption.bold()).tracking(1.3).foregroundStyle(PaletteEG.red)
                        Text(session.question.prompt).font(.system(.largeTitle, design: .rounded, weight: .black))
                            .fixedSize(horizontal: false, vertical: true)
                    }.padding(.top, 22)
                    if session.question.kind.usesTokens {
                        sentenceBuilder(session)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(session.optionOrder, id: \.self) { option in
                                AnswerOptionEG(text: option, selected: session.selectedAnswer == option,
                                    checked: session.checked, correct: TestSessionEG.normalize(option) == TestSessionEG.normalize(session.question.answer)) {
                                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { model.select(option) }
                                }
                            }
                        }
                    }
                    if session.checked { feedback(session).transition(.opacity.combined(with: .move(edge: .bottom))) }
                }.padding(20).id(session.question.id)
            }
            PrimaryButtonEG(title: session.checked ? L10nEG.string("Дальше") : L10nEG.string("Проверить"), icon: session.checked ? "arrow.right" : nil) {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    if session.checked { model.next() } else { model.check() }
                }
            }.disabled(!session.checked && !session.canCheck).padding(20)
                .background(PaletteEG.background)
        }
    }
    private func sentenceBuilder(_ session: TestSessionEG) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("ВАШ ОТВЕТ").font(.caption2.bold()).tracking(1).foregroundStyle(PaletteEG.secondary)
                if session.constructedSentence.isEmpty {
                    Text("Нажимайте на слова ниже").foregroundStyle(PaletteEG.secondary).font(.body).frame(minHeight: 50)
                } else {
                    FlowLayoutEG {
                        ForEach(session.constructedSentence, id: \.self) { index in
                            WordChipEG(text: session.tokenOrder[index], selected: true) { animateToken(index) }.disabled(session.checked)
                        }
                    }
                }
            }.cardEG()
            FlowLayoutEG {
                ForEach(Array(session.tokenOrder.enumerated()), id: \.offset) { index, token in
                    let used = session.constructedSentence.contains(index)
                    WordChipEG(text: token, selected: false) { animateToken(index) }
                        .opacity(used ? 0.2 : 1).disabled(used || session.checked)
                        .accessibilityHidden(used)
                }
            }
            if !session.checked { Text("Чтобы убрать слово, нажмите на него в ответе.").font(.footnote).foregroundStyle(PaletteEG.secondary) }
        }
    }
    private func animateToken(_ index: Int) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) { model.toggleToken(index) }
    }
    private func feedback(_ session: TestSessionEG) -> some View {
        let correct = session.answers.last?.correct == true
        return VStack(alignment: .leading, spacing: 12) {
            Label(correct ? L10nEG.string("Правильно!") : L10nEG.string("Почти. Разберёмся вместе"), systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline).foregroundStyle(correct ? PaletteEG.success : PaletteEG.red)
            if !correct { Text("Правильный ответ: \(session.question.answer)").font(.body.bold()) }
            if model.settings.explanations { Text(session.question.explanation).font(.body).lineSpacing(3) }
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background((correct ? PaletteEG.success : PaletteEG.red).opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
            .accessibilityElement(children: .combine)
    }
}

struct QuestionHeaderEG: View {
    let title: String
    let index: Int
    let total: Int
    let close: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: close) { Image(systemName: "xmark").font(.headline).frame(width: 44, height: 44).background(PaletteEG.subtle, in: Circle()) }
                    .accessibilityLabel("Закрыть тест")
                Text(title).font(.subheadline.bold()).lineLimit(2).frame(maxWidth: .infinity)
                Text("\(index) / \(total)").font(.subheadline.monospacedDigit().bold()).foregroundStyle(PaletteEG.red)
            }
            ProgressBarEG(value: Double(index - 1) / Double(total))
        }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
    }
}

struct AnswerOptionEG: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let text: String
    let selected: Bool
    let checked: Bool
    let correct: Bool
    let action: () -> Void
    private var color: Color { checked && correct ? PaletteEG.success : checked && selected ? PaletteEG.red : selected ? PaletteEG.navy : PaletteEG.border }
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text).font(.title3.weight(.semibold)).foregroundStyle(PaletteEG.ink).multilineTextAlignment(.leading)
                Spacer(minLength: 12)
                Image(systemName: checked && correct ? "checkmark.circle.fill" : checked && selected ? "xmark.circle.fill" : selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(color).font(.title3)
            }.padding(18).frame(maxWidth: .infinity, minHeight: 62)
                .background(selected || (checked && correct) ? color.opacity(0.06) : PaletteEG.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(color, lineWidth: selected || (checked && correct) ? 2 : 1))
        }.buttonStyle(PressStyleEG()).disabled(checked).accessibilityAddTraits(selected ? [.isSelected] : [])
            .keyframeAnimator(initialValue: AnswerMotionEG(), trigger: checked) { [reduceMotion] content, motion in
                content.offset(x: !reduceMotion && checked && selected && !correct ? motion.x : 0)
                    .scaleEffect(!reduceMotion && checked && correct ? motion.scale : 1)
            } keyframes: { _ in
                KeyframeTrack(\.x) {
                    LinearKeyframe(-6, duration: 0.06)
                    LinearKeyframe(6, duration: 0.06)
                    LinearKeyframe(-3, duration: 0.06)
                    LinearKeyframe(0, duration: 0.06)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.025, duration: 0.12)
                    LinearKeyframe(1, duration: 0.15)
                }
            }
    }
}

struct WordChipEG: View {
    let text: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(.body.weight(.semibold)).foregroundStyle(selected ? PaletteEG.onAccent : PaletteEG.navy)
                .padding(.horizontal, 14).padding(.vertical, 12).frame(minHeight: 46)
                .background(selected ? PaletteEG.navy : PaletteEG.surface, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? .clear : PaletteEG.border))
        }.buttonStyle(PressStyleEG()).accessibilityHint(selected ? Text("Убрать из ответа") : Text("Добавить в ответ"))
    }
}

#Preview {
    let model = ViewModelEG(preview: true)
    if let topic = model.topics.first { model.start(topic, stage: .choice) }
    return TestViewEG(model: model)
}

private struct AnswerMotionEG {
    var x: CGFloat = 0
    var scale: CGFloat = 1
}
