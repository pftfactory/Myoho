import SwiftUI
import UIKit
import MessageUI
import StoreKit

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

    /// 背景グラデーション（淡いブルー系で少し華やかに）
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.92, green: 0.96, blue: 1.0),
                Color(.systemGroupedBackground)
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

    /// 上部のヒーローカード（アプリのコンセプトを視覚的にアピール）
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor.opacity(0.25),
                                    Color.accentColor.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    // シンプルなマスコットアイコン的なイメージ
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("AIがあなたの「なぜ？」に寄りそう簿記3級アプリ")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("むずかしい専門用語や仕訳も、登録済みの質問から選ぶだけ。分からないところだけをピンポイントでAIに聞けます。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // 特徴バッジ
            HStack(spacing: 8) {
                featureBadge(text: "📘 仕訳・用語をやさしく解説")
                featureBadge(text: "✨ 初心者・独学でも安心")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.95),
                    Color.white.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 10)
        .padding(.horizontal)
    }

    /// ヒーローカード内で使用する特徴バッジ
    private func featureBadge(text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(Color.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.08))
            )
    }

    /// 「学習カテゴリ」見出し
    private var categoryHeader: some View {
        Text("学習カテゴリ")
            .font(.headline.weight(.semibold))
            .padding(.horizontal)
            .padding(.top, 8)
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

    /// 検索テキストでフィルタした質問一覧（スペース区切りの複数キーワード対応）
    private var filteredQuestions: [String] {
        // 前後の空白を削除
        let rawText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        // 何も入力されていない場合は全件表示
        guard !rawText.isEmpty else {
            return questions
        }

        // スペース区切りでキーワードを分割（連続スペースは除外）
        let keywords = rawText
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // 有効なキーワードがない場合は全件表示
        guard !keywords.isEmpty else {
            return questions
        }

        // すべてのキーワードを含む質問だけを残す（AND検索）
        return questions.filter { question in
            keywords.allSatisfy { keyword in
                question.localizedCaseInsensitiveContains(keyword)
            }
        }
    }

    var body: some View {
        ZStack {
            // 背景グラデーション（HomeViewと揃える）
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.92, green: 0.96, blue: 1.0),
                    Color(.systemGroupedBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // 画面上部に固定される検索フォームカード
                searchFieldCard

                // 質問一覧のみスクロール
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // セクションヘッダー
                        Text("質問一覧")
                            .font(.headline.weight(.semibold))
                            .padding(.horizontal)

                        // 質問カード群
                        VStack(spacing: 12) {
                            ForEach(filteredQuestions, id: \.self) { question in
                                NavigationLink(destination: QuestionDetailView(question: question)) {
                                    questionCard(for: question)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.top, 16)
        }
        .navigationTitle(category.title)
        .onAppear {
            if questions.isEmpty {
                loadQuestions()
            }
        }
    }

    /// 検索フォームを柔らかいカードで包む（少し目立つデザイン）
    private var searchFieldCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(width: 32, height: 32)

                TextField("キーワードで検索", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
            }

            Text("スペース区切りで複数キーワード検索可")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground).opacity(0.95),
                            Color.white.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.accentColor.opacity(0.18), radius: 14, x: 0, y: 8)
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }

    /// 1件分の質問カード
    private func questionCard(for question: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(question)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 8)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.95))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
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

            // 下部の過剰な余白を防ぐために Spacer は使わない
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                    
                    let baseText = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    let disclaimer = """
                    
                    ※AIの回答は完璧ではありません。時々間違えたり誤解を招く内容があることがあります。使用にあたっては予めご理解をお願い致します。
                    """
                    answerText = baseText + disclaimer
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
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.vertical, 8)

            HStack {
                Label("AIの回答", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    activeSheet = .share
                } label: {
                    Label("この質問と回答を共有", systemImage: "square.and.arrow.up")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 4)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.systemBackground).opacity(0.98),
                                Color(.secondarySystemBackground).opacity(0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)

                ScrollView {
                    Text(answerText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(16)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200, alignment: .top)
            .padding(.top, 4)
            .padding(.bottom, 4)
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
        @State private var isShowingMailSheet: Bool = false
        @State private var isShowingMailErrorAlert: Bool = false

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

                    Button {
                        Task {
                            await restorePurchases()
                        }
                    } label: {
                        HStack {
                            Text("購入を復元")
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("各種ポリシー")) {
                    Link(destination: URL(string: "https://pftfactory.github.io/BOKISUKE-PrivacyPolicy/")!) {
                        HStack {
                            Text("プライバシーポリシー")
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://pftfactory.github.io/BOKISUKE-EULA/")!) {
                        HStack {
                            Text("利用規約（EULA）")
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        HStack {
                            Text("Apple標準EULA（英語）")
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("開発者へのフィードバック")) {
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            isShowingMailSheet = true
                        } else {
                            isShowingMailErrorAlert = true
                        }
                    } label: {
                        HStack {
                            Text("新しい質問をリクエストする")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("追加してほしい質問や改善要望等がありましたらフィードバックをお願い致します。なお全てのフィードバックには個別に返信できませんが、機能改善の参考にさせて頂きます。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    
                }

                /*
                Section(header: Text("AI設定")) {
                    Text("将来的に、AIの呼び出し回数や回答モードのデフォルト設定などをここに追加できます。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                 */
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingPlanSheet) {
                PlanSelectionView(isSubscribed: $isSubscribed)
            }
            .sheet(isPresented: $isShowingMailSheet) {
                MailView(
                    subject: "【BOKISUKE】質問リクエスト",
                    toRecipients: ["info@pftfactory.deca.jp"],
                    body: makeFeedbackMailBody()
                )
            }
            .alert("メールを送信できません", isPresented: $isShowingMailErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("この端末でメールアカウントが設定されていないため、アプリからメールを送信できません。")
            }
        }
    
        /// App Store の情報からサブスクリプション購入を復元する
        private func restorePurchases() async {
            do {
                // 最新の購入情報を同期
                try await AppStore.sync()

                var hasActiveSubscription = false

                // 現在有効なエンタイトルメント（購入状態）を確認
                for await result in Transaction.currentEntitlements {
                    if case .verified(let transaction) = result {
                        if transaction.productType == .autoRenewable {
                            hasActiveSubscription = true
                            break
                        }
                    }
                }

                // メインスレッドでアプリ内の状態を更新
                await MainActor.run {
                    isSubscribed = hasActiveSubscription
                    BokiAPIService.shared.updateSubscriptionStatus(isSubscribed: hasActiveSubscription)
                }

                print("[SettingsView] Restore purchases completed. isSubscribed = \(hasActiveSubscription)")
            } catch {
                print("[SettingsView] Failed to restore purchases: \(error)")
            }
        }

        /// フィードバックメールの本文を組み立てる（末尾にアプリ名・バージョン・日時を付与）
        private func makeFeedbackMailBody() -> String {
            let header = """
いつもBOKISUKEをご利用いただきありがとうございます。
追加してほしい質問や、分かりにくかったポイントを、できるだけ具体的にご記入ください。

--------------------
（ここからご自由にお書きください）

"""

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = formatter.string(from: Date())

            let appName = "BOKISUKE"
            let appVersion = currentAppVersion()

            let footer = """
--------------------
アプリ名: \(appName)
バージョン: \(appVersion)
送信日時: \(dateString)
"""

            return header + footer
        }

        /// Info.plist から現在のアプリバージョンを取得
        private func currentAppVersion() -> String {
            let info = Bundle.main.infoDictionary
            let shortVersion = info?["CFBundleShortVersionString"] as? String
            let build = info?["CFBundleVersion"] as? String

            if let shortVersion, let build, !shortVersion.isEmpty, !build.isEmpty {
                return "\(shortVersion) (\(build))"
            } else if let shortVersion, !shortVersion.isEmpty {
                return shortVersion
            } else {
                return "1.0.0"
            }
        }
    }

    /// プラン選択画面（無料 / 有料（サブスク））
    struct PlanSelectionView: View {
        @Binding var isSubscribed: Bool
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject var subscriptionManager: BokiSubscriptionManager

        var body: some View {
            NavigationStack {
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("プランを選択")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("ご利用スタイルにあわせて、無料プランと有料プランからお選びいただけます。いつでも設定画面から変更できます。")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            VStack(spacing: 20) {
                                // 無料プランカード
                                planCard(
                                    title: "無料プラン",
                                    price: "無料",
                                    description: freePlanDescription,
                                    isSelected: !subscriptionManager.isSubscribed
                                ) {
                                    // ローカル状態として無料プランに戻す（App Store側の解約はユーザーのApple ID設定で行う前提）
                                    isSubscribed = false
                                    BokiAPIService.shared.updateSubscriptionStatus(isSubscribed: false)
                                    dismiss()
                                }
                                
                                // 有料プランカード
                                planCard(
                                    title: "有料プラン（サブスク）",
                                    price: "月額¥100",
                                    description: paidPlanDescription,
                                    isSelected: subscriptionManager.isSubscribed
                                ) {
                                    Task {
                                        await subscriptionManager.purchase()
                                        // StoreKit2側で購読が有効化されたら、AppStorage側の状態も同期
                                        isSubscribed = subscriptionManager.isSubscribed
                                        if subscriptionManager.isSubscribed {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                        }
                        .padding(.top, 24)
                    }
                }
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
            price: String,
            description: String,
            isSelected: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: {
                if !isSelected {
                    action()
                }
            }) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(price)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Spacer()
                        Text(isSelected ? "現在のプラン" : "このプランに切り替え")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? Color.primary.opacity(0.6) : .white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color(.systemGray5) : Color.accentColor)
                            )
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
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

    /// 開発者への質問リクエストなどに使うメール送信用ラッパー
    struct MailView: UIViewControllerRepresentable {
        @Environment(\.dismiss) private var dismiss

        let subject: String
        let toRecipients: [String]
        let body: String

        class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
            let parent: MailView

            init(parent: MailView) {
                self.parent = parent
            }

            func mailComposeController(
                _ controller: MFMailComposeViewController,
                didFinishWith result: MFMailComposeResult,
                error: Error?
            ) {
                controller.dismiss(animated: true) {
                    self.parent.dismiss()
                }
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        func makeUIViewController(context: Context) -> MFMailComposeViewController {
            let vc = MFMailComposeViewController()
            vc.setSubject(subject)
            vc.setToRecipients(toRecipients)
            vc.setMessageBody(body, isHTML: false)
            vc.mailComposeDelegate = context.coordinator
            return vc
        }

        func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
            // 画面更新時に特別な処理は不要
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
        .padding(.bottom, 10)
    }
