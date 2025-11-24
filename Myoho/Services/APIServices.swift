//
//  APIServices.swift
//  Myoho
//
//  Created by pftFactory on 2025/11/15.
//

import Foundation

// MARK: - 回答モード（簿記用）
/// 質問に対する回答のスタイルを指定するモード。
enum BokiAnswerMode: String, CaseIterable, Identifiable {
    case simple      // 小学生にも分かるように
    case standard    // 標準的な教科書レベルで
    case detailed    // 具体例を加えて詳細に

    var id: String { rawValue }

    /// プロンプトに埋め込む説明文
    var instruction: String {
        switch self {
        case .simple:
            return "小学生にも分かるように"
        case .standard:
            return "日商簿記3級の標準的レベルで"
        case .detailed:
            return "福沢諭吉風に"
        }
    }
    /// instruction に応じた「モデル向けの追加説明」（ユーザーには見せない想定の指示）
    var hiddenNote: String {
        switch self {
        case .simple:
            return "専門用語をできるだけ使わず、小学生でもイメージしやすい身近な例え話を1つ以上入れてください。また、効果的に絵文字等も使い親しみやすい表記にしたり、専門用語や難しい感じにはふりがなをつけて"
        case .standard:
            return "日商簿記3級の標準的な教科書レベルの用語を用いながら、難しい用語にはかんたんな補足説明を1文添えて"
        case .detailed:
            return "福沢諭吉が学生に向けて説明するように、19世紀日本で使われていた口語調で"
        }
    }
}

// MARK: - プロンプト生成
/// 質問とモードから、ChatGPT に渡すユーザープロンプト文字列を生成する。
struct BokiPromptBuilder {
    static func buildPrompt(question: String, mode: BokiAnswerMode) -> String {
        """
        あなたは、信頼性の高い情報を提示できる高精度なファクトベースのAI簿記講師です。そして、あなたの役割は日商簿記3級を勉強している初心者に簿記を構成する各種概念をわかりやすく理解させることです。
        次の「学習者の質問」に答えてください。

        回答スタイルの条件:
        - 【重要】\(mode.instruction)、説明してください。
        - 追加説明: \(mode.hiddenNote)、説明してください。
        - 以下の項目の順番に説明してください。
          1. 概要
          2. 解説
          3. 要点・ポイント
        - レスポンスの項目表記には#や*のような記号を使わず1や①や絵文字等を使用して下さい。
        - わからない場合は回答する必要はない。
        - 根拠／出典（可能なら一次情報）を必ず明記

        学習者の質問:
        \"\"\"
        \(question)
        \"\"\"
        """
    }
}

// MARK: - モデル定義

/// ChatGPT 互換のメッセージ構造（簿記用）
struct BokiChatMessage: Codable {
    let role: String
    let content: String
}

/// API 呼び出し回数とキャッシュされたメッセージを保持する構造体（簿記用）
struct BokiAPICacheData: Codable {
    var callDate: Date
    var cachedMessage: BokiChatMessage?
    var callCount: Int
}

// MARK: - プロトコル定義

protocol BokiAPIServiceProtocol {
    /// 今日の残り呼び出し可能回数があるかどうか
    var hasRemainingCalls: Bool { get }

    /// メッセージを送信し、AIの返答を返す
    func send(
        message: String,
        model: String,
        maxTokens: Int?,
        temperature: Double?,
        completion: @escaping (BokiChatMessage?) -> Void
    )
}

// MARK: - APIService 本体（簿記用）

final class BokiAPIService: BokiAPIServiceProtocol {
    
    /// 設定画面と共有するサブスク状態の保存キー
    private static let subscriptionStorageKey = "BokiSubscriptionIsPaid"
    /// 無料プランの利用開始日を保存するキー
    private static let freePlanStartDateKey = "BokiFreePlanStartDate"

    // MARK: - App Store Connect サブスクリプション設定（BOKISUKE）

    /// App Store Connect で登録した BOKISUKE のサブスクリプション製品ID
    /// - 製品ID: myoho.subscription.monthly
    static let subscriptionProductID: String = "myoho.subscription.monthly"

    /// App Store Connect 上のサブスクリプショングループの参照名
    /// - グループ参照名: MyohoSubscriptions
    static let subscriptionGroupReferenceName: String = "MyohoSubscriptions"

    /// App Store Connect 上のサブスクリプショングループID
    /// - サブスクリプショングループID: 21839190
    static let subscriptionGroupID: String = "21839190"
    
    /// シングルトン的に共有して使う想定（1回当たりの最大トークンおよび1日当たり問い合わせ回数の設定）
    static let shared = BokiAPIService(
        freeCallsPerDay: 10,
        paidCallsPerDay: 100,
        freePlanMaxDays: 30,  // 無料版は30日間利用可能（必要に応じて変更）
        isSubscribedUser: false,
        cacheNamespace: "MyohoBokiQA",
        defaultMaxTokens: 700,
        defaultTemperature: 0.7
    )
    /// 無料プランの1日あたりの呼び出し上限
    var freePlanDailyLimit: Int {
        freeCallsPerDay
    }

    /// 有料プランの1日あたりの呼び出し上限
    var paidPlanDailyLimit: Int {
        paidCallsPerDay
    }

    /// 無料プランに期間制限がある場合、その最大日数（nil の場合は期間制限なし）
    var freePlanLimitDays: Int? {
        freePlanMaxDays
    }

    /// 無料プランの残り利用可能日数（サブスク中や期間制限なしの場合は nil）
    var remainingFreePlanDays: Int? {
        // 有料プランの場合は制限なし扱い
        if isSubscribedUser { return nil }
        guard let maxDays = freePlanMaxDays else { return nil }
        guard let start = freePlanStartDate else { return maxDays }
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let today = cal.startOfDay(for: Date())
        let usedDays = cal.dateComponents([.day], from: startDay, to: today).day ?? 0
        let remaining = maxDays - usedDays
        return max(remaining, 0)
    }

    // MARK: - プロパティ

    private let freeCallsPerDay: Int
    private let paidCallsPerDay: Int
    private var isSubscribedUser: Bool
    /// 無料プランが利用できる最大日数（nil の場合は期間制限なし）
    private let freePlanMaxDays: Int?
    /// 無料プランの利用開始日（UserDefaults から復元）
    private var freePlanStartDate: Date?

    private var allowedCallsPerDay: Int {
        isSubscribedUser ? paidCallsPerDay : freeCallsPerDay
    }

    private let cacheNamespace: String
    private let cacheURL: URL
    private let defaultMaxTokens: Int
    private let defaultTemperature: Double
    private let disableCache: Bool

    private let dateFormatter: DateFormatter

    /// 今日の呼び出し回数が上限に達しているかどうかを判定
    var hasRemainingCalls: Bool {
        // 無料プランの利用期間が終了している場合は呼び出し不可
        if !isSubscribedUser, let maxDays = freePlanMaxDays {
            if freePlanStartDate == nil {
                // まだ開始日が記録されていない場合は、初回利用として本日を開始日にする
                let now = Date()
                freePlanStartDate = now
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: Self.freePlanStartDateKey)
            } else if let start = freePlanStartDate {
                let cal = Calendar.current
                let startDay = cal.startOfDay(for: start)
                let today = cal.startOfDay(for: Date())
                let usedDays = cal.dateComponents([.day], from: startDay, to: today).day ?? 0
                if usedDays >= maxDays {
                    return false
                }
            }
        }

        guard let cache = loadCache(),
              Calendar.current.isDateInToday(cache.callDate)
        else { return true }
        return cache.callCount < allowedCallsPerDay
    }

    // MARK: - 初期化

    init(
        freeCallsPerDay: Int,
        paidCallsPerDay: Int,
        freePlanMaxDays: Int? = nil,
        isSubscribedUser: Bool = false,
        cacheNamespace: String = "Default",
        defaultMaxTokens: Int = 1000,
        defaultTemperature: Double = 0.7,
        disableCache: Bool = false
    ) {
        self.freeCallsPerDay = freeCallsPerDay
        self.paidCallsPerDay = paidCallsPerDay
        self.freePlanMaxDays = freePlanMaxDays
        //self.isSubscribedUser = isSubscribedUser

        // 設定画面の「現在のプラン」と同じキーからサブスク状態を復元する
        if let stored = UserDefaults.standard.object(forKey: Self.subscriptionStorageKey) as? Bool {
            self.isSubscribedUser = stored
            print("[BokiAPIService] init: loaded subscription state from UserDefaults = \(stored)")
        } else {
            // 保存がなければ引数の値（デフォルト false = 無料）を採用
            self.isSubscribedUser = isSubscribedUser
        }

        // 無料プラン利用開始日を UserDefaults から復元
        if let ts = UserDefaults.standard.object(forKey: Self.freePlanStartDateKey) as? TimeInterval {
            self.freePlanStartDate = Date(timeIntervalSince1970: ts)
        } else {
            self.freePlanStartDate = nil
        }

        self.cacheNamespace = cacheNamespace
        self.defaultMaxTokens = defaultMaxTokens
        self.defaultTemperature = defaultTemperature
        self.disableCache = disableCache

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "APICache_\(cacheNamespace).json"
        self.cacheURL = docs.appendingPathComponent(fileName)

        self.dateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            f.timeZone = .current
            return f
        }()
    }

    // MARK: - メイン: send

    func send(
        message: String,
        model: String = "gpt-5-nano",
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        completion: @escaping (BokiChatMessage?) -> Void
    ) {
        let requestId = UUID().uuidString
        print("[BokiAPIService][\(requestId)] send called: disableCache=\(disableCache), hasRemainingCalls=\(hasRemainingCalls), model=\(model)")

        // 無料プランに利用期間が設定されており、まだ開始日が記録されていない場合は、ここで開始日を記録
        if !isSubscribedUser, let _ = freePlanMaxDays, freePlanStartDate == nil {
            let now = Date()
            freePlanStartDate = now
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: Self.freePlanStartDateKey)
            print("[BokiAPIService][\(requestId)] free plan start date recorded: \(now)")
        }

        // ── 呼び出し上限チェック（当日＆上限超えならキャッシュ返却） ──
        if !disableCache,
           let cache = loadCache(),
           Calendar.current.isDateInToday(cache.callDate),
           cache.callCount >= allowedCallsPerDay {
            print("[BokiAPIService][\(requestId)] returning CACHED message (namespace=\(cacheNamespace)) callCount=\(cache.callCount)/\(allowedCallsPerDay)")
            DispatchQueue.main.async {
                completion(cache.cachedMessage)
            }
            return
        }

        // ── エンドポイント（LIFTMe+ と同様の2本立て） ──
        let endpoints: [URL] = [
            URL(string: "https://myodo-api.onrender.com/chat")!,   // Render
            URL(string: "https://www.massqu.com/chat")!            // ConoHa
        ]

        let tokens = maxTokens ?? defaultMaxTokens
        let temp = temperature ?? defaultTemperature
        let body: [String: Any] = [
            "model": model,
            "messages": [[
                "role": "user",
                "content": message
            ]],
            "max_tokens": tokens,
            "temperature": temp
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            print("[BokiAPIService][\(requestId)] failed to encode body")
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let raceQueue = DispatchQueue(label: "api.race.queue.myoho.boki")
        var completed = false
        var tasks: [URLSessionDataTask] = []

        func finishOnce(_ result: BokiChatMessage?) {
            raceQueue.sync {
                if completed { return }
                completed = true
                tasks.forEach { $0.cancel() }
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }

        for url in endpoints {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.timeoutInterval = 30
            req.httpBody = bodyData

            print("[BokiAPIService][\(requestId)] prepared URLRequest to \(url.absoluteString) bodyBytes=\(bodyData.count) at \(Date())")

            let task = URLSession.shared.dataTask(with: req) { data, _, error in
                if let error = error as NSError?,
                   error.domain == NSURLErrorDomain,
                   error.code == NSURLErrorCancelled {
                    // レースで負けたキャンセルは無視
                    return
                }
                if let error = error {
                    print("[BokiAPIService][\(requestId)] transport error (\(url.host ?? "")): \(error.localizedDescription)")
                }

                guard
                    let data = data,
                    let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let choices = jsonObject["choices"] as? [[String: Any]],
                    let firstChoice = choices.first,
                    let messageDict = firstChoice["message"] as? [String: Any],
                    let content = messageDict["content"] as? String
                else {
                    let raw = data.flatMap { String(data: $0, encoding: .utf8) } ?? "nil"
                    print("[BokiAPIService][\(requestId)] decode failure (\(url.host ?? "")): raw=\(raw)")

                    raceQueue.sync {
                        if tasks.allSatisfy({ $0.state != .running }) && !completed {
                            completed = true
                            DispatchQueue.main.async { completion(nil) }
                        }
                    }
                    return
                }

                let aiMsg = BokiChatMessage(role: "assistant", content: content)
                print("[BokiAPIService][\(requestId)] parsed content (\(url.host ?? "")): \(content)")

                var newCache = BokiAPICacheData(callDate: Date(),
                                                cachedMessage: aiMsg,
                                                callCount: 1)
                if let old = self.loadCache(), Calendar.current.isDateInToday(old.callDate) {
                    newCache.callCount = old.callCount + 1
                }
                if !self.disableCache {
                    self.saveCache(newCache)
                    print("[BokiAPIService][\(requestId)] cache saved (callCount=\(newCache.callCount))")
                } else {
                    print("[BokiAPIService][\(requestId)] cache disabled, not saving")
                }

                finishOnce(aiMsg)
            }
            tasks.append(task)
            task.resume()
        }
    }

    // MARK: - サブスクリプション状態更新
    
    /// 設定画面の「ご利用プラン」で選択された内容に応じて、API上限を切り替える
    /// - Parameter isSubscribed: 無料プランなら false / 有料（サブスク）プランなら true
    func updateSubscriptionStatus(isSubscribed: Bool) {
        print("[BokiAPIService] updateSubscriptionStatus called: isSubscribed=\(isSubscribed)")
        // BokiAPIService 内部のフラグを更新
        self.isSubscribedUser = isSubscribed
        // SettingsView の @AppStorage と同じキーで永続化
        UserDefaults.standard.set(isSubscribed, forKey: Self.subscriptionStorageKey)
    }

    // MARK: - キャッシュ管理

    private func loadCache() -> BokiAPICacheData? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return try? decoder.decode(BokiAPICacheData.self, from: data)
    }

    private func saveCache(_ cache: BokiAPICacheData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        if let data = try? encoder.encode(cache) {
            try? data.write(to: cacheURL)
        }
    }
}
