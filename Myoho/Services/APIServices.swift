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
            return "日商簿記3級レベルの標準的なレベルで"
        case .detailed:
            return "具体例を交えて詳細に。"
        }
    }
}

// MARK: - プロンプト生成
/// 質問とモードから、ChatGPT に渡すユーザープロンプト文字列を生成する。
struct BokiPromptBuilder {
    static func buildPrompt(question: String, mode: BokiAnswerMode) -> String {
        """
        あなたは、日商簿記3級を勉強している初心者をやさしくサポートする簿記の講師です。
        次の「学習者の質問」に答えてください。

        回答スタイルの条件:
        - \(mode.instruction)
        - 相手は勉強があまり得意ではなく、専門用語が多いと混乱しやすいと想定してください。
        - できるだけ、
          1. まず結論をやさしく一文で
          2. 次に理由やしくみを段階的に
          3. 最後に「これだけおぼえればOK」というまとめ
          の順番で説明してください。

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
    /// シングルトン的に共有して使う想定
    static let shared = BokiAPIService(
        allowedCallsPerDay: 100,
        cacheNamespace: "MyohoBokiQA",
        defaultMaxTokens: 1200,
        defaultTemperature: 0.7
    )

    // MARK: - プロパティ

    private let allowedCallsPerDay: Int
    private let cacheNamespace: String
    private let cacheURL: URL
    private let defaultMaxTokens: Int
    private let defaultTemperature: Double
    private let disableCache: Bool

    private let dateFormatter: DateFormatter

    /// 今日の呼び出し回数が上限に達しているかどうかを判定
    var hasRemainingCalls: Bool {
        guard let cache = loadCache(),
              Calendar.current.isDateInToday(cache.callDate)
        else { return true }
        return cache.callCount < allowedCallsPerDay
    }

    // MARK: - 初期化

    init(
        allowedCallsPerDay: Int,
        cacheNamespace: String = "Default",
        defaultMaxTokens: Int = 1000,
        defaultTemperature: Double = 0.7,
        disableCache: Bool = false
    ) {
        self.allowedCallsPerDay = allowedCallsPerDay
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
