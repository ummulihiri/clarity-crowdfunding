;; Crowda - Crowdfunding Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-deadline-passed (err u102))
(define-constant err-campaign-not-found (err u103))
(define-constant err-goal-not-reached (err u104))
(define-constant err-already-claimed (err u105))

;; Data structures
(define-map campaigns
    { campaign-id: uint }
    {
        owner: principal,
        goal: uint,
        deadline: uint,
        raised: uint,
        claimed: bool
    }
)

(define-map contributions
    { campaign-id: uint, contributor: principal }
    { amount: uint }
)

;; Data variables
(define-data-var next-campaign-id uint u1)

;; Public functions
(define-public (create-campaign (goal uint) (deadline uint))
    (let
        (
            (campaign-id (var-get next-campaign-id))
        )
        (asserts! (> goal u0) err-invalid-amount)
        (asserts! (> deadline block-height) err-deadline-passed)
        
        (map-set campaigns
            { campaign-id: campaign-id }
            {
                owner: tx-sender,
                goal: goal,
                deadline: deadline,
                raised: u0,
                claimed: false
            }
        )
        
        (var-set next-campaign-id (+ campaign-id u1))
        (ok campaign-id)
    )
)

(define-public (contribute (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) err-campaign-not-found))
            (amount (stx-get-balance tx-sender))
        )
        (asserts! (<= block-height (get deadline campaign)) err-deadline-passed)
        (asserts! (> amount u0) err-invalid-amount)
        
        ;; Transfer STX to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update campaign raised amount
        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { raised: (+ (get raised campaign) amount) })
        )
        
        ;; Record contribution
        (map-set contributions
            { campaign-id: campaign-id, contributor: tx-sender }
            { amount: amount }
        )
        
        (ok true)
    )
)

(define-public (claim-funds (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) err-campaign-not-found))
        )
        (asserts! (is-eq (get owner campaign) tx-sender) err-owner-only)
        (asserts! (> block-height (get deadline campaign)) err-deadline-passed)
        (asserts! (>= (get raised campaign) (get goal campaign)) err-goal-not-reached)
        (asserts! (not (get claimed campaign)) err-already-claimed)
        
        ;; Transfer funds to campaign owner
        (try! (as-contract (stx-transfer? (get raised campaign) tx-sender (get owner campaign))))
        
        ;; Mark campaign as claimed
        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { claimed: true })
        )
        
        (ok true)
    )
)

(define-public (refund (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) err-campaign-not-found))
            (contribution (unwrap! (map-get? contributions { campaign-id: campaign-id, contributor: tx-sender }) err-campaign-not-found))
        )
        (asserts! (> block-height (get deadline campaign)) err-deadline-passed)
        (asserts! (< (get raised campaign) (get goal campaign)) err-goal-not-reached)
        
        ;; Return contribution to sender
        (try! (as-contract (stx-transfer? (get amount contribution) tx-sender tx-sender)))
        
        ;; Clear contribution record
        (map-delete contributions { campaign-id: campaign-id, contributor: tx-sender })
        
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-campaign (campaign-id uint))
    (map-get? campaigns { campaign-id: campaign-id })
)

(define-read-only (get-contribution (campaign-id uint) (contributor principal))
    (map-get? contributions { campaign-id: campaign-id, contributor: contributor })
)