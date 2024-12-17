;; DeedVault - Enhanced Independent Decentralized Property Registry
;; Includes sale mechanisms and burn-and-reissue functionality

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-token-exists (err u103))
(define-constant err-invalid-token (err u104))
(define-constant err-transfer-failed (err u105))
(define-constant err-insufficient-funds (err u106))
(define-constant err-not-for-sale (err u107))
(define-constant err-already-burned (err u108))

;; Data Maps and Variables
(define-map deeds
    uint  ;; deed-id
    {
        owner: principal,
        asset-type: (string-ascii 64),
        description: (string-ascii 256),
        uri: (string-ascii 256),
        creation-time: uint,
        last-modified: uint,
        is-locked: bool,
        is-burned: bool,
        price: (optional uint),
        for-sale: bool,
        transfer-history: (list 10 principal)
    }
)

(define-map burned-to-reissued
    uint  ;; burned-deed-id
    uint  ;; reissued-deed-id
)

(define-data-var last-deed-id uint u0)

;; Private Functions
(define-private (is-valid-deed-id (deed-id uint))
    (<= deed-id (var-get last-deed-id))
)

(define-private (is-deed-owner (deed-id uint))
    (match (map-get? deeds deed-id)
        deed (is-eq (get owner deed) tx-sender)
        false
    )
)

(define-private (record-transfer (deed-id uint) (new-owner principal))
    (match (map-get? deeds deed-id)
        deed 
        (let
            (
                (current-history (get transfer-history deed))
                (updated-history (unwrap-panic (as-max-len? (append current-history new-owner) u10)))
            )
            (map-set deeds deed-id
                (merge deed {
                    owner: new-owner,
                    last-modified: block-height,
                    transfer-history: updated-history,
                    for-sale: false,
                    price: none
                })
            )
            (ok true)
        )
        err-token-not-found
    )
)

;; Public Functions
(define-public (mint-deed (asset-type (string-ascii 64))
                         (description (string-ascii 256))
                         (uri (string-ascii 256)))
    (let
        (
            (new-deed-id (+ (var-get last-deed-id) u1))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (map-set deeds new-deed-id
            {
                owner: tx-sender,
                asset-type: asset-type,
                description: description,
                uri: uri,
                creation-time: block-height,
                last-modified: block-height,
                is-locked: false,
                is-burned: false,
                price: none,
                for-sale: false,
                transfer-history: (list tx-sender)
            }
        )
        (var-set last-deed-id new-deed-id)
        (ok new-deed-id)
    )
)

(define-public (list-deed-for-sale (deed-id uint) (sale-price uint))
    (let
        (
            (deed (unwrap! (map-get? deeds deed-id) err-token-not-found))
        )
        (asserts! (is-valid-deed-id deed-id) err-invalid-token)
        (asserts! (is-deed-owner deed-id) err-not-token-owner)
        (asserts! (not (get is-locked deed)) err-transfer-failed)
        (asserts! (not (get is-burned deed)) err-already-burned)
        
        (map-set deeds deed-id
            (merge deed {
                for-sale: true,
                price: (some sale-price),
                last-modified: block-height
            })
        )
        (ok true)
    )
)

(define-public (purchase-deed (deed-id uint))
    (let
        (
            (deed (unwrap! (map-get? deeds deed-id) err-token-not-found))
            (price (unwrap! (get price deed) err-not-for-sale))
        )
        (asserts! (is-valid-deed-id deed-id) err-invalid-token)
        (asserts! (get for-sale deed) err-not-for-sale)
        (asserts! (not (get is-burned deed)) err-already-burned)
        
        ;; Transfer STX payment to current owner
        (try! (stx-transfer? price tx-sender (get owner deed)))
        
        ;; Transfer deed ownership
        (try! (record-transfer deed-id tx-sender))
        (ok true)
    )
)

(define-public (burn-deed (deed-id uint))
    (let
        (
            (deed (unwrap! (map-get? deeds deed-id) err-token-not-found))
        )
        (asserts! (is-valid-deed-id deed-id) err-invalid-token)
        (asserts! (is-deed-owner deed-id) err-not-token-owner)
        (asserts! (not (get is-burned deed)) err-already-burned)
        
        (map-set deeds deed-id
            (merge deed {
                is-burned: true,
                last-modified: block-height,
                for-sale: false,
                price: none
            })
        )
        (ok true)
    )
)

(define-public (reissue-deed (burned-deed-id uint) 
                            (asset-type (string-ascii 64))
                            (description (string-ascii 256))
                            (uri (string-ascii 256)))
    (let
        (
            (burned-deed (unwrap! (map-get? deeds burned-deed-id) err-token-not-found))
            (new-deed-id (+ (var-get last-deed-id) u1))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get is-burned burned-deed) err-invalid-token)
        
        ;; Mint new deed
        (try! (mint-deed asset-type description uri))
        
        ;; Record reissuance relationship
        (map-set burned-to-reissued burned-deed-id new-deed-id)
        
        (ok new-deed-id)
    )
)

;; Read-Only Functions
(define-read-only (get-deed-info (deed-id uint))
    (ok (map-get? deeds deed-id))
)

(define-read-only (get-deed-owner (deed-id uint))
    (match (map-get? deeds deed-id)
        deed (ok (get owner deed))
        err-token-not-found
    )
)

(define-read-only (get-total-deeds)
    (ok (var-get last-deed-id))
)

(define-read-only (is-deed-burned (deed-id uint))
    (match (map-get? deeds deed-id)
        deed (ok (get is-burned deed))
        err-token-not-found
    )
)

(define-read-only (get-reissued-deed-id (burned-deed-id uint))
    (ok (map-get? burned-to-reissued burned-deed-id))
)

(define-read-only (get-deed-sale-info (deed-id uint))
    (match (map-get? deeds deed-id)
        deed (ok {
            for-sale: (get for-sale deed),
            price: (get price deed)
        })
        err-token-not-found
    )
)

(define-read-only (get-deed-history (deed-id uint))
    (match (map-get? deeds deed-id)
        deed (ok (get transfer-history deed))
        err-token-not-found
    )
)