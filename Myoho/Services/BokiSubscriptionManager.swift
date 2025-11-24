//
//  BokiSubscriptionManager.swift
//  Myoho
//
//  Created by pftFactory on 2025/11/22.
//
//
//  BokiSubscriptionManager.swift
//  BOKISUKE
//

//
//  BokiSubscriptionManager.swift
//  BOKISUKE
//

import Foundation
import StoreKit
import Combine

/// BOKISUKE のサブスクリプションを管理するクラス
/// - 購入 / リストア / 購読状態チェックを担当
@MainActor
final class BokiSubscriptionManager: ObservableObject {
    static let shared = BokiSubscriptionManager()
    
    /// 現在サブスク中かどうか（UI バインド用）
    @Published var isSubscribed: Bool = false
    
    /// 対象となる StoreKit の Product
    @Published private(set) var product: Product?
    
    /// 通信中フラグ（ローディング表示などに利用可能）
    @Published var isLoading: Bool = false
    
    /// 直近のエラー（あれば）
    @Published var lastErrorMessage: String?
    
    private init() {
        Task {
            await refreshProducts()
            await refreshCurrentEntitlement()
            observeTransactions()
        }
    }
    
    // MARK: - 商品情報の取得
    
    /// App Store Connect から対象サブスクの Product を取得
    func refreshProducts() async {
        do {
            let ids = [BokiAPIService.subscriptionProductID]
            let products = try await Product.products(for: ids)
            self.product = products.first
        } catch {
            lastErrorMessage = "サブスクリプション情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 現在の購読状態チェック
    
    /// 現在有効なサブスクリプションがあるかどうかを確認
    func refreshCurrentEntitlement() async {
        var isActive = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == BokiAPIService.subscriptionProductID,
               transaction.revocationDate == nil {
                isActive = true
                break
            }
        }
        
        isSubscribed = isActive
        BokiAPIService.shared.updateSubscriptionStatus(isSubscribed: isActive)
    }
    
    // MARK: - 購入処理
    
    /// サブスクリプションを購入
    func purchase() async {
        guard let product else {
            await refreshProducts()
            guard let product = self.product else {
                lastErrorMessage = "サブスクリプション商品が取得できませんでした。しばらくしてから再度お試しください。"
                return
            }
            await purchaseProduct(product)
            return
        }
        await purchaseProduct(product)
    }
    
    private func purchaseProduct(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    // 購入成功
                    isSubscribed = true
                    BokiAPIService.shared.updateSubscriptionStatus(isSubscribed: true)
                    await transaction.finish()
                } else {
                    lastErrorMessage = "購入の検証に失敗しました。"
                }
            case .userCancelled:
                // キャンセルされた場合は何もしない
                break
            case .pending:
                // ファミリー共有 / 承認待ちなど
                break
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = "購入処理に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - リストア処理
    
    /// 購入を復元（別端末 / 再インストール時など）
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        
        var foundActive = false
        
        // currentEntitlements を読むだけで「復元」に相当
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == BokiAPIService.subscriptionProductID,
               transaction.revocationDate == nil {
                foundActive = true
            }
        }
        
        isSubscribed = foundActive
        BokiAPIService.shared.updateSubscriptionStatus(isSubscribed: foundActive)
        
        if !foundActive {
            lastErrorMessage = "有効なサブスクリプションが見つかりませんでした。"
        }
    }
    
    // MARK: - トランザクション監視
    
    /// サブスクリプション状態の変化を常時監視
    private func observeTransactions() {
        let productID = BokiAPIService.subscriptionProductID
        
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                
                if case .verified(let transaction) = result,
                   transaction.productID == productID {
                    
                    let isActive = (transaction.revocationDate == nil)
                    await MainActor.run {
                        self.isSubscribed = isActive
                        BokiAPIService.shared.updateSubscriptionStatus(isSubscribed: isActive)
                    }
                    await transaction.finish()
                }
            }
        }
    }
}
