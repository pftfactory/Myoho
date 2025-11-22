import SwiftUI
import UIKit

struct HomeView: View {
    // 簿記3級の質問カテゴリ一覧（必要に応じてタイトル・plist名を調整してください）
    private let categories: [QuestionCategory] = [
        QuestionCategory(title: "全般的な質問", plistName: "Questions_A"),
        QuestionCategory(title: "用語・概念の質問", plistName: "Questions_B"),
        QuestionCategory(title: "勉強方法・メンタル", plistName: "Questions_C")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                ScrollView {
                    mainContent
                }
            }
            .toolbar {
                // タイトルは中央に配置しつつ、右上に設定ボタンを重ねて表示
                ToolbarItem(placement: .principal) {
                    ZStack {
                        VStack(spacing: 2) {
                            Text("BOKISUKE")   // ← アプリ名（必要なら変更してください）
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.top, 30)
                            Text("簿記3級合格を目指すあなたをAIがお手伝い")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        // 右上に重ねる設定ボタン
                        HStack {
                            Spacer()
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape")
                                    .imageScale(.large)
                                    .accessibilityLabel("設定")
                            }
                            .padding(.trailing, -12)
                        }
                    }
                }
            }
        }
    }

    /// 背景グラデーション
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGroupedBackground),
                Color(.secondarySystemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    /// スクロール可能なメインコンテンツ
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            heroCard
            categoryHeader
            categoryCardsSection
            footerSection
        }
        .padding(.top, 10)
    }

    /// 上部のヒーローカード（アプリのコンセプトを表示）
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あらかじめ登録されている質問を選んでいくだけの簡単操作。分からない単語等で検索すれば素早く適切な質問を見つけられます。")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }

    /// 「学習カテゴリ」見出し
    private var categoryHeader: some View {
        Text("学習カテゴリ")
            .font(.headline)
            .padding(.horizontal)
    }

    /// カテゴリカード群
    private var categoryCardsSection: some View {
        VStack(spacing: 12) {
            ForEach(categories.indices, id: \.self) { index in
                let category = categories[index]
                NavigationLink(destination: QuestionListView(category: category)) {
                    categoryRow(for: category)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    /// 1件分のカテゴリカード行
    private func categoryRow(for category: QuestionCategory) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.1))
                Image(systemName: iconName(for: category))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(subtitle(for: category))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.95))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    /// カテゴリごとのアイコン（SF Symbols）
    private func iconName(for category: QuestionCategory) -> String {
        switch category.plistName {
        case "Questions_A":
            return "lightbulb"
        case "Questions_B":
            return "book.closed"
        case "Questions_C":
            return "heart.text.square"
        default:
            return "questionmark.circle"
        }
    }

    /// カテゴリごとの説明文
    private func subtitle(for category: QuestionCategory) -> String {
        switch category.plistName {
        case "Questions_A":
            return "勉強そのものへの不安や、全体像に関する質問はこちら"
        case "Questions_B":
            return "用語や概念が分からないときに、かみ砕いて教えてくれます"
        case "Questions_C":
            return "勉強の進め方やメンタル面のモヤモヤを相談できます"
        default:
            return "このカテゴリに関する質問を一覧から選べます"
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
        VStack(spacing: 12) {

            // 🔍 カスタム装飾付き検索フォーム
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("キーワードで検索", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.blue.opacity(0.18), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal)

            // 質問一覧
            List(filteredQuestions, id: \.self) { question in
                NavigationLink(destination: QuestionDetailView(question: question)) {
                    Text(question)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(category.title)
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
    @State private var isShowingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var activeSheet: ActiveSheet?

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
        .alert(Text(alertTitle), isPresented: $isShowingAlert) {
            Button("有料プランを検討する") {
                activeSheet = .plan
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .share:
                ActivityView(activityItems: [shareText])
            case .plan:
                NavigationStack {
                    SettingsView()
                }
            }
        }
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
            let service = BokiAPIService.shared

            // ① トライアル期間超過チェック（これを最優先）
            if let remaining = service.remainingFreePlanDays, remaining <= 0 {
                answerText = ""
                errorText = ""
                alertTitle = "無料お試し期間が終了しました"
                alertMessage = "無料プランの利用可能期間が終了しました。有料プランに切り替えると、引き続きAIによるサポートをご利用いただけます。"
                isShowingAlert = true
                return
            }

            // ② 呼び出し上限チェック
            guard service.hasRemainingCalls else {
                answerText = ""
                errorText = ""
                alertTitle = "AIの呼び出し上限"
                alertMessage = "本日のAI呼び出し上限に達しました。有料プランに切り替えると、より多くの回数をご利用いただけます。"
                isShowingAlert = true
                return
            }

            let prompt = BokiPromptBuilder.buildPrompt(question: question, mode: selectedMode)
            print("[QuestionDetailView] sending prompt: \(prompt)")
            isLoading = true
            answerText = ""
            errorText = ""

            service.send(
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

            HStack {
                Spacer()
                Button {
                    activeSheet = .share
                } label: {
                    Label("この質問と回答を共有", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 4)

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

    /// 共有用のテキスト（質問 + AIの回答 + App Store案内）
    private var shareText: String {
        var parts: [String] = []
        parts.append("【質問】\n\(question)")
        if !answerText.isEmpty {
            parts.append("【AIの回答】\n\(answerText)")
        }
        // 最下部にアプリの案内とApp Storeリンクを追加
        parts.append("""
        
        App Storeで「BOKISUKE」で検索!!
        https://apps.apple.com/jp/app/idXXXXXXXXXX
        """)
        return parts.joined(separator: "\n\n")
    }

    /// QuestionDetailView内で使用するシート種別
    private enum ActiveSheet: Identifiable {
        case share
        case plan

        var id: Int {
            switch self {
            case .share: return 0
            case .plan:  return 1
            }
        }
    }
}

    /// 設定画面
    struct SettingsView: View {
        @AppStorage("BokiSubscriptionIsPaid") private var isSubscribed: Bool = false
        @State private var isShowingPlanSheet: Bool = false

        private var currentPlanLabel: String {
            isSubscribed ? "有料（サブスク）" : "無料プラン"
        }

        var body: some View {
            Form {
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("アプリ名")
                        Spacer()
                        Text("BOKISUKE")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("ご利用プラン")) {
                    Button {
                        isShowingPlanSheet = true
                    } label: {
                        HStack {
                            Text("現在のプラン")
                            Spacer()
                            Text(currentPlanLabel)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("AI設定")) {
                    Text("将来的に、AIの呼び出し回数や回答モードのデフォルト設定などをここに追加できます。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingPlanSheet) {
                PlanSelectionView(isSubscribed: $isSubscribed)
            }
        }
    }

    /// プラン選択画面（無料 / 有料（サブスク））
    struct PlanSelectionView: View {
        @Binding var isSubscribed: Bool
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("プランを選択")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("BOKISUKEでは、無料プランと有料（サブスク）プランの2種類から選べます。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        planCard(
                            title: "無料プラン",
                            description: freePlanDescription,
                            isSelected: !isSubscribed
                        ) {
                            selectPlan(isSubscribed: false)
                        }

                        planCard(
                            title: "有料プラン（サブスク）",
                            description: paidPlanDescription,
                            isSelected: isSubscribed
                        ) {
                            selectPlan(isSubscribed: true)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
                .navigationTitle("プラン選択")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
            }
        }
        
        /// 無料プラン向け説明文（シングルトンの制限回数 + お試し期間を反映）
        private var freePlanDescription: String {
            let service = BokiAPIService.shared
            let limit = service.freePlanDailyLimit

            if let maxDays = service.freePlanLimitDays {
                // お試し期間付き無料プラン
                if let remaining = service.remainingFreePlanDays {
                    return "AIの回答回数には制限がありますが、主要な機能を無料でお試しいただけます。（1日あたり\(limit)回まで／お試し期間は最大\(maxDays)日・残り\(max(remaining, 0))日）"
                } else {
                    // 何らかの理由で残日数が算出できない場合は最大日数のみ表示
                    return "AIの回答回数には制限がありますが、主要な機能を無料でお試しいただけます。（1日あたり\(limit)回まで／お試し期間は最大\(maxDays)日）"
                }
            } else {
                // 期間制限なしの場合は従来どおり回数制限のみ表示
                return "AIの回答回数には制限がありますが、主要な機能を無料でお試しいただけます。（1日あたり\(limit)回まで）"
            }
        }

        /// 有料プラン向け説明文（シングルトンの制限回数を反映）
        private var paidPlanDescription: String {
            let limit = BokiAPIService.shared.paidPlanDailyLimit
            return "AIの回答回数の上限が増え、より快適に学習を進められます。（1日あたり\(limit)回まで）"
        }
        

        private func planCard(
            title: String,
            description: String,
            isSelected: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.headline)
                            if isSelected {
                                Text("選択中")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                            }
                        }
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .imageScale(.large)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
        }

        private func selectPlan(isSubscribed: Bool) {
            self.isSubscribed = isSubscribed
            BokiAPIService.shared.updateSubscriptionStatus(isSubscribed: isSubscribed)
            dismiss()
        }
    }

    /// UIKitのUIActivityViewControllerをSwiftUIから使うためのラッパー
    struct ActivityView: UIViewControllerRepresentable {
        let activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems,
                                     applicationActivities: applicationActivities)
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
            // 更新処理は特になし
        }
    }

    /// フッター（バージョン + ©2025 pftFactory）
    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Version 1.0.0")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("© 2025 pftFactory")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
