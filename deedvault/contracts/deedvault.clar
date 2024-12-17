;; DeedVault - Independent Decentralized Property Registry
;; Standalone smart contract for managing deed tokens

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-token-exists (err u103))
(define-constant err-invalid-token (err u104))
(define-constant err-transfer-failed (err u105))

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
        is-locked: bool
    }
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
                is-locked: false
            }
        )
        (var-set last-deed-id new-deed-id)
        (ok new-deed-id)
    )
)

(define-public (transfer-deed (deed-id uint) (recipient principal))
    (let
        (
            (deed (unwrap! (map-get? deeds deed-id) err-token-not-found))
        )
        (asserts! (is-valid-deed-id deed-id) err-invalid-token)
        (asserts! (is-deed-owner deed-id) err-not-token-owner)
        (asserts! (not (get is-locked deed)) err-transfer-failed)
        
        (map-set deeds deed-id
            (merge deed {
                owner: recipient,
                last-modified: block-height
            })
        )
        (ok true)
    )
)

(define-public (update-deed-metadata (deed-id uint)
                                   (new-description (string-ascii 256))
                                   (new-uri (string-ascii 256)))
    (let
        (
            (deed (unwrap! (map-get? deeds deed-id) err-token-not-found))
        )
        (asserts! (is-valid-deed-id deed-id) err-invalid-token)
        (asserts! (is-deed-owner deed-id) err-not-token-owner)
        
        (map-set deeds deed-id
            (merge deed {
                description: new-description,
                uri: new-uri,
                last-modified: block-height
            })
        )
        (ok true)
    )
)

(define-public (toggle-deed-lock (deed-id uint))
    (let
        (
            (deed (unwrap! (map-get? deeds deed-id) err-token-not-found))
        )
        (asserts! (is-valid-deed-id deed-id) err-invalid-token)
        (asserts! (is-deed-owner deed-id) err-not-token-owner)
        
        (map-set deeds deed-id
            (merge deed {
                is-locked: (not (get is-locked deed)),
                last-modified: block-height
            })
        )
        (ok true)
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

(define-read-only (is-deed-locked (deed-id uint))
    (match (map-get? deeds deed-id)
        deed (ok (get is-locked deed))
        err-token-not-found
    )
)