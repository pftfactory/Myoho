import SwiftUI

struct HomeView: View {
    // 簿記3級の質問カテゴリ一覧（必要に応じてタイトル・plist名を調整してください）
    private let categories: [QuestionCategory] = [
        QuestionCategory(title: "全般的な質問", plistName: "Questions_A"),
        QuestionCategory(title: "用語・概念の質問", plistName: "Questions_B"),
        QuestionCategory(title: "勉強方法・メンタル", plistName: "Questions_C")
    ]

    var body: some View {
        NavigationStack {
            List(categories) { category in
                NavigationLink(destination: QuestionListView(category: category)) {
                    Text(category.title)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("ボキ助")   // ← アプリ名（必要なら変更してください）
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 30)
                        Text("簿記3級合格を目指して勉強中のあなたをAIがお手伝いします")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

/// 質問カテゴリ（plistファイル名とタイトルを持つ）
struct QuestionCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let plistName: String

    init(title: String, plistName: String) {
        self.title = title
        self.plistName = plistName
        self.id = plistName
    }
}

/// 選択されたカテゴリに対応する質問一覧画面（検索バー付き）
struct QuestionListView: View {
    let category: QuestionCategory

    @State private var questions: [String] = []
    @State private var searchText: String = ""

    /// 検索テキストでフィルタした質問一覧
    private var filteredQuestions: [String] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            return questions
        }
        return questions.filter { $0.localizedCaseInsensitiveContains(keyword) }
    }

    var body: some View {
        List(filteredQuestions, id: \.self) { question in
            NavigationLink(destination: QuestionDetailView(question: question)) {
                Text(question)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .navigationTitle(category.title)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "キーワードで検索"
        )
        .onAppear {
            if questions.isEmpty {
                loadQuestions()
            }
        }
    }

    /// カテゴリに対応する plist から質問一覧を読み込む
    private func loadQuestions() {
        guard let url = Bundle.main.url(forResource: category.plistName, withExtension: "plist") else {
            print("[QuestionListView] plist not found: \(category.plistName).plist")
            questions = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            if let array = plist as? [String] {
                questions = array
            } else {
                print("[QuestionListView] plist is not [String]: \(category.plistName).plist")
                questions = []
            }
        } catch {
            print("[QuestionListView] failed to load plist \(category.plistName).plist: \(error.localizedDescription)")
            questions = []
        }
    }
}

struct QuestionDetailView: View {
    let question: String

    @State private var selectedMode: BokiAnswerMode = .simple
    @State private var isLoading: Bool = false
    @State private var answerText: String = ""
    @State private var errorText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            questionHeader
            modeSelectionSection
            sendButtonSection

            if isLoading {
                loadingSection
            }

            if !errorText.isEmpty {
                errorSection
            }

            if !answerText.isEmpty {
                answerSection
            }

            Spacer()
        }
        .padding()
        .navigationTitle("質問の詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("選んだ質問")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(question)
                .font(.title3)
                .padding(.top, 4)
        }
    }

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("回答モードをえらんでください")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(Array(BokiAnswerMode.allCases), id: \.self) { mode in
                modeRow(for: mode)
            }
        }
    }

    private func modeRow(for mode: BokiAnswerMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: selectedMode == mode ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selectedMode == mode ? .accentColor : .secondary)
                Text(mode.instruction)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }

    private var sendButtonSection: some View {
        Button {
            // 呼び出し上限チェック
            guard BokiAPIService.shared.hasRemainingCalls else {
                errorText = "本日のAI呼び出し上限に達しました。日付が変わってから再度お試しください。"
                answerText = ""
                return
            }

            let prompt = BokiPromptBuilder.buildPrompt(question: question, mode: selectedMode)
            print("[QuestionDetailView] sending prompt: \(prompt)")
            isLoading = true
            answerText = ""
            errorText = ""

            BokiAPIService.shared.send(
                message: prompt,
                model: "gpt-5-nano",
                maxTokens: nil,
                temperature: nil
            ) { response in
                isLoading = false
                if let content = response?.content {
                    print("[QuestionDetailView] received content: \(content)")
                    answerText = content.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    print("[QuestionDetailView] no content received from API")
                    errorText = "AIからの回答を取得できませんでした。ネットワーク環境やAPIサーバーの状態を確認して、しばらく時間をおいてから再度お試しください。"
                }
            }
        } label: {
            Label("この質問をAIに送る", systemImage: "paperplane")
                .font(.body)
        }
        .buttonStyle(.borderedProminent)
        .padding(.top, 8)
    }

    private var loadingSection: some View {
        HStack {
            ProgressView()
            Text("AIが回答を作成中です…")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 12)
    }

    private var errorSection: some View {
        Text(errorText)
            .font(.caption)
            .foregroundColor(.red)
            .padding(.top, 8)
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 8)

            Text("AIの回答")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView {
                Text(answerText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
            }
            .frame(maxHeight: .infinity)
            .padding(.bottom, 20)
        }
    }
}
